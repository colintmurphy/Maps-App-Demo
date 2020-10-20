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
    func updateMapWithResults()
    func failed(with error: CustomError)
}

protocol AppleMapViewModelProtocol {
    
    var delegate: AppleViewModelProtocol? { get set }
    
    func loadAnnotations(with query: String)
    func resetDataSource()
}

class AppleMapViewModel: GeocoderHandler {
    
    // MARK: - Properties
    
    private var dataSource: [MKAnnotation] = []
    private var searchType = SearchType.coffee
    
    var searchCompleter: MKLocalSearchCompleter?
    var searchResults: [MKLocalSearchCompletion] = []
    
    weak var delegate: AppleViewModelProtocol?
    
    // MARK: - Return Data
    
    func getSearchType() -> SearchType {
        return searchType
    }
    
    func getAnnotations() -> [MKAnnotation] {
        return dataSource
    }
    
    // MARK: - Handle Search Type
    
    func searchWithCompleter(with query: String, controller: AppleMapViewController, region: MKCoordinateRegion) {
        
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = controller
        searchCompleter?.region = region
        searchCompleter?.queryFragment = query
    }
    
    func search(with query: String, region: MKCoordinateRegion?) {
        
        switch searchType {
        
        case .coffee:
            loadAnnotations(with: query)
            
        case .location:
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            guard let region = region else { return }
            searchRequest.region = region
            loadAnnotation(with: searchRequest)
            
        case .general:
            guard !searchResults.isEmpty else { return }
            loadAnnotations(with: searchResults)// { _ in }
        }
        delegate?.updateMapWithResults()
    }
    
    // MARK: - Get Annotations
    
    func loadAnnotations(with searchCompletionResults: [MKLocalSearchCompletion]) {
        
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
            self.dataSource = annotations
            self.delegate?.updateMapWithResults()
        }
    }
    
    func loadAnnotation(with searchRequest: MKLocalSearch.Request) {
        
        var annotations: [CustomAnnotation] = []
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                return
            }

            for item in response.mapItems {
                annotations.append(CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name ?? "", subtitle: ""))
            }
            self.dataSource = annotations
            self.delegate?.updateMapWithResults()
        }
    }
    
    func loadAnnotations(with query: String) {
        
        delegate?.showActivity()
        geocoding(query: query) { location, error in
            if let error = error {
                self.delegate?.hideActivity()
                self.delegate?.failed(with: error)
            } else if let location = location {
                
                self.fetchData(with: location) { annotations, error in
                    self.delegate?.hideActivity()
                    if let error = error {
                        self.delegate?.failed(with: error)
                    } else if let annotations = annotations {
                        self.dataSource = annotations
                        self.delegate?.updateMapWithResults()
                    }
                }
            }
        }
    }
    
    // MARK: - Update UI
    
    func changeSearchType(with type: SearchType) -> String {
        
        searchType = type
        switch searchType {
        case .coffee:
            return "Where do you want to find a cup of joe?"
        
        case .location:
            return "What location are you looking for"
        
        case .general:
            return "Enter a search"
        }
    }
    
    func generateCustomAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotation else { return nil }
        let view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation") {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
        }
        
        view.image = UIImage(named: "purple-pin72")
        view.canShowCallout = true
        //view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        return view
    }
    
    // MARK: - Move Camera
    
    func moveCameraToShowSingleAnnotation() -> MKCoordinateRegion? {
        
        guard !dataSource.isEmpty else { return nil }
        let delta = 2.5
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        return MKCoordinateRegion(center: dataSource[0].coordinate, span: span)
    }

    func moveCameraToShowAnnotations() -> MKCoordinateRegion? {
        
        guard !dataSource.isEmpty else { return nil }
        var minLongitude = dataSource[0].coordinate.longitude
        var maxLongitude = dataSource[0].coordinate.longitude
        var minLatitude = dataSource[0].coordinate.latitude
        var maxLatitude = dataSource[0].coordinate.latitude
        
        for annotation in dataSource {
            if annotation.coordinate.longitude > maxLongitude {
                maxLongitude = annotation.coordinate.longitude
            } else if annotation.coordinate.longitude < minLongitude {
                minLongitude = annotation.coordinate.longitude
            }
            
            if annotation.coordinate.latitude > maxLatitude {
                maxLatitude = annotation.coordinate.latitude
            } else if annotation.coordinate.latitude < minLatitude {
                minLatitude = annotation.coordinate.latitude
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
    
    // MARK: - Fetch Data
    
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
