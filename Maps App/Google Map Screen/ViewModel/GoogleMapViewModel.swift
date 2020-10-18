//
//  GoogleViewModel.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import Foundation
import GoogleMaps

protocol GoogleViewModelProtocol: AnyObject {
    
    func didFinishLoad()
    func showActivity()
    func hideActivity()
    func failed(with error: CustomError)
}

protocol GoogleMapViewModelProtocol {
    
    var delegate: GoogleViewModelProtocol? { get set }
    
    func loadAnnotations(with query: String)
    func resetDataSource()
}

class GoogleMapViewModel: GeocoderHandler {
    
    // MARK: - Properties
    
    weak var delegate: GoogleViewModelProtocol?
    
    // MARK: - Public Methods
    
    func moveCameraToShow(markers: [CustomMarker]) -> GMSCameraUpdate? {
        
        var bounds = GMSCoordinateBounds()
        for marker in markers {
            bounds = bounds.includingCoordinate(marker.coordinate)
        }
        return GMSCameraUpdate.fit(bounds)
    }
    
    func loadMarkers(with query: String, completion: @escaping ([CustomMarker]?, CustomError?) -> Void) {
        
        delegate?.showActivity()
        geocoding(query: query) { location, error in
            if let error = error {
                self.delegate?.hideActivity()
                self.delegate?.failed(with: error)
            } else if let location = location {
                
                self.fetchData(with: location) { markers, error in
                    if let error = error {
                        self.delegate?.hideActivity()
                        self.delegate?.failed(with: error)
                    } else if let markers = markers {
                        self.delegate?.hideActivity()
                        completion(markers, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchData(with location: CLLocation, completion: @escaping ([CustomMarker]?, CustomError?) -> Void) {
        
        NetworkManager.manager.request(ShopResponse.self, withCoordinate: location.coordinate) { result in
            switch result {
            case .success(let shopResponse):

                var markers: [CustomMarker] = []
                for shop in shopResponse.shops {
                    markers.append(CustomMarker(place: shop))
                }
                completion(markers, nil)
                
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
