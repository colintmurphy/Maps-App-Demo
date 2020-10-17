//
//  AppleMapViewModel.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import MapKit

protocol AppleViewModelProtocol: AnyObject {
    
    func didFinishLoad()
    func showActivity()
    func hideActivity()
    func failed(with error: CustomError)
}

protocol AppleMapViewModelProtocol {
    
    var delegate: AppleViewModelProtocol? { get set }
    
    func loadAnnotations(with query: String)
    func resetDataSource()
}

class AppleMapViewModel {
    
    // MARK: - Properties
    
    weak var delegate: AppleViewModelProtocol?
    
    // MARK: - Public Methods
    
    func getAnnotationOfSearch(with searchRequest: MKLocalSearch.Request, completion: @escaping ([CustomAnnotation]?) -> Void) {
        
        var annotations: [CustomAnnotation] = []
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                completion(nil)
                return
            }

            for item in response.mapItems {
                annotations.append(CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name ?? "", subtitle: ""))
            }
            completion(annotations)
        }
    }
    
    func moveCameraTo(annotation: MKAnnotation) -> MKCoordinateRegion? {
        
        let delta = 2.5
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        return MKCoordinateRegion(center: annotation.coordinate, span: span)
    }
    
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
    }
    
    func loadAnnotations(with query: String, completion: @escaping ([CustomAnnotation]?, CustomError?) -> Void) {
        
        delegate?.showActivity()
        geocoding(query: query) { location, error in
            if let error = error {
                self.delegate?.hideActivity()
                self.delegate?.failed(with: error)
            } else if let location = location {
                
                self.fetchData(with: location) { annotations, error in
                    if let error = error {
                        self.delegate?.hideActivity()
                        self.delegate?.failed(with: error)
                    } else if let annotations = annotations {
                        self.delegate?.hideActivity()
                        completion(annotations, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func geocoding(query: String, completion: @escaping (CLLocation?, CustomError?) -> Void) {
        
        CLGeocoder().geocodeAddressString(query) { placemarks, _ in
            if let placemarks = placemarks,
               let location = placemarks.first?.location {
                completion(location, nil)
            } else {
                completion(nil, CustomError.noLocationFound)
            }
        }
    }
    
    private func fetchData(with location: CLLocation, completion: @escaping ([CustomAnnotation]?, CustomError?) -> Void) {
        
        NetworkManager.manager.request(ShopResponse.self, withCoordinate: location.coordinate) { result in
            switch result {
            case .success(let shopResponse):

                var annotations: [CustomAnnotation] = []
                for shop in shopResponse.shops {
                    annotations.append(CustomAnnotation(place: shop))
                }
                completion(annotations, nil)
                
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
