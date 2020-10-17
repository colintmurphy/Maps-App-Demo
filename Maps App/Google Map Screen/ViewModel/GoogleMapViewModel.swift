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
    
    /*
    func moveCameraToShow(annotations: [MKAnnotation]) -> MKCoordinateRegion? {
        
        guard !annotations.isEmpty else { return nil }
        var minLongitude = annotations[0].coordinate.longitude
        var maxLongitude = annotations[0].coordinate.longitude
        var minLatitude = annotations[0].coordinate.latitude
        var maxLatitude = annotations[0].coordinate.latitude
        
        for annotations in annotations {
            if annotations.coordinate.longitude > maxLongitude {
                maxLongitude = annotations.coordinate.longitude
            } else if annotations.coordinate.longitude < minLongitude {
                minLongitude = annotations.coordinate.longitude
            }
            
            if annotations.coordinate.latitude > maxLatitude {
                maxLatitude = annotations.coordinate.latitude
            } else if annotations.coordinate.latitude < minLatitude {
                minLatitude = annotations.coordinate.latitude
            }
        }
        
        var region = MKCoordinateRegion()
        region.center.latitude = minLatitude - (minLatitude - maxLatitude)
        region.center.longitude = minLongitude - (minLongitude - maxLongitude)
        region.span.latitudeDelta = abs(minLatitude - maxLatitude)
        region.span.longitudeDelta = abs(minLongitude - maxLongitude)
        return region
    }*/
    
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
