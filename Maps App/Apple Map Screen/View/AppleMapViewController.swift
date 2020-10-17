//
//  AppleMapViewController.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import CoreLocation
import MapKit
import UIKit

class AppleMapViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.showsUserLocation = true
            mapView.showsCompass = true
            mapView.delegate = self
        }
    }
    
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
        }
    }
    
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    
    // MARK: - Properties
    
    private var viewModel = AppleMapViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }
    
    private var searchResults: [MKLocalSearchCompletion] = [] {
        didSet {
            updateMapWithCompletionResults()
        }
    }
    
    private lazy var locationHandler = LocationHandler(delegate: self)
    private var dataSource: [MKAnnotation] = []
    private var searchType = SearchType.coffee
    private var searchCompleter: MKLocalSearchCompleter?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationHandler.getUserLocation()
    }
    
    // MARK: - IBActions
    
    @IBAction private func changeSearchType(_ sender: Any) {
        guard let type = SearchType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        searchType = type
        updateSearchBarPlaceholder()
    }
    
    // MARK: - Load Annotations
    
    private func updateMapWithCompletionResults() {
        
        guard !searchResults.isEmpty else { return }
        viewModel.loadAnnotations(with: searchResults) { annotations in
            guard !annotations.isEmpty else { return }
            self.updateViewWithDataSource(annotations: annotations)
            self.updateRegionWithDataSource()
        }
    }
    
    private func loadCoffeeShopsInMap(with query: String) {
        
        viewModel.loadAnnotations(with: query) { annotations, error in
            if let annotations = annotations {
                self.updateViewWithDataSource(annotations: annotations)
                self.updateRegionWithDataSource()
            } else if let error = error {
                print(error)
            }
        }
    }
    
    // MARK: - MKLocalSearches
    
    private func localSearch(with query: String) {
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapView.region
        
        viewModel.loadAnnotation(with: searchRequest) { annotations in
            guard let annotations = annotations,
                  !annotations.isEmpty else { return }
            self.updateViewWithDataSource(annotations: annotations)
            self.updateRegionForSearchRequest()
        }
    }
    
    private func localSearchCompleter(with query: String) {
        
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.region = mapView.region
        searchCompleter?.queryFragment = query
    }
    
    private func updateViewWithDataSource(annotations: [CustomAnnotation]) {
        dataSource.removeAll()
        dataSource.append(contentsOf: annotations)
        mapView.addAnnotations(dataSource)
    }
    
    // MARK: - Region Updates
    
    private func updateRegionWithDataSource() {
        guard let region = viewModel.moveCameraToShow(annotations: dataSource) else { return }
        mapView.setRegion(region, animated: true)
    }
    
    private func updateRegionForSearchRequest() {
        guard !dataSource.isEmpty,
            let region = viewModel.moveCameraTo(annotation: dataSource[0]) else { return }
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - UI/UX
    
    private func setup() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    private func updateSearchBarPlaceholder() {
        
        switch searchType {
        case .coffee:
            searchBar.placeholder = "Where do you want to find a cup of joe?"
        
        case .location:
            searchBar.placeholder = "What location are you looking for"
        
        case .general:
            searchBar.placeholder = "Enter a search"
        }
    }
}

// MARK: - AppleMapViewModelDelegate

extension AppleMapViewController: AppleViewModelProtocol {
    
    func showActivity() {
        activityIndicator.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
    }
    
    func didFinishLoad() { }
    func failed(with error: CustomError) { }
}

// MARK: - MKMapViewDelegate

extension AppleMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotation else { return nil }
        let view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation") {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
        }
        
        // MKMarkerAnnotationView vs MKAnnotationView
        view.image = UIImage(named: "purple-pin72")
        view.canShowCallout = true
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) { }
}

// MARK: - LocationHandlerDelegate

extension AppleMapViewController: LocationHandlerDelegate {
    
    func received(location: CLLocation) { }
    
    func didFail(withError error: Error) {
        print(error)
    }
}

// MARK: - UISearchBarDelegate

extension AppleMapViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespaces) else {
            didFail(withError: CustomError.emptyTextField)
            return
        }
        searchBar.resignFirstResponder()
        
        switch searchType {
        case .coffee:
            loadCoffeeShopsInMap(with: query)
            
        case .location:
            localSearch(with: query)
            
        case .general:
            localSearchCompleter(with: query)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension AppleMapViewController: MKLocalSearchCompleterDelegate {
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}

// MARK: - UISearchResultsUpdating

extension AppleMapViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
    }
}
