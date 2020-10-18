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

class AppleMapViewModel: GeocoderHandler {
    
    // MARK: - Properties
    
    weak var delegate: AppleViewModelProtocol?
    
    // MARK: - Get Annotations
    
    func loadAnnotations(with searchCompletionResults: [MKLocalSearchCompletion], completion: @escaping ([CustomAnnotation]) -> Void) {
        
        let group = DispatchGroup()
        var annotations: [CustomAnnotation] = []
        
        for result in searchCompletionResults {
            group.enter()
            geocoding(query: result.subtitle) { location, _ in
                if let location = location {
                    annotations.append(CustomAnnotation(coordinate: location.coordinate, title: result.title, subtitle: result.subtitle))
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(annotations)
        }
    }
    
    func loadAnnotation(with searchRequest: MKLocalSearch.Request, completion: @escaping ([CustomAnnotation]?) -> Void) {
        
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
    
    // MARK: - Move Camera
    
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
        
        let zoom = 1.33
        var region = MKCoordinateRegion()
        region.center.latitude = (minLatitude + maxLatitude) / 2
        region.center.longitude = (minLongitude + maxLongitude) / 2
        region.span.latitudeDelta = abs(minLatitude - maxLatitude) * zoom
        region.span.longitudeDelta = abs(minLongitude - maxLongitude) * zoom
        return region
    }
    
    // MARK: - Private Methods
    
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
