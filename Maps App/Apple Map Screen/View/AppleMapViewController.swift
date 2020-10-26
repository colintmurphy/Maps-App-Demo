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
    
    private var viewModel = AppleMapViewModel()
    private var completionQuery = ""
    private lazy var locationHandler = LocationHandler(delegate: self)
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        viewModel.delegate = self
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationHandler.getUserLocation()
    }
    
    // MARK: - IBActions
    
    @IBAction private func changeSearchType(_ sender: Any) {
        guard let type = SearchType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        searchBar.placeholder = viewModel.changeSearchType(with: type)
    }
    
    // MARK: - Region Updates
    
    private func showAllAnnotationsOnMap() {
        guard let region = viewModel.moveCameraToShowAnnotations() else { return }
        mapView.setRegion(region, animated: true)
    }
    
    private func showSingleAnnotationOnMap() {
        guard let region = viewModel.moveCameraToShowSingleAnnotation() else { return }
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
    
    func updateMapWithResults() {
        
        mapView.addAnnotations(viewModel.getAnnotations())
        switch viewModel.getSearchType() {
        case .coffee, .general:
            showAllAnnotationsOnMap()
            
        case .location:
            showSingleAnnotationOnMap()
        }
    }
    
    func appendMapWithResults(annotations: [CustomAnnotation]) {
        mapView.addAnnotations(annotations)
    }
}

// MARK: - MKMapViewDelegate

extension AppleMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let view = viewModel.generateCustomAnnotation(annotation: annotation, mapView: mapView) {
            return view
        }
        return nil
    }
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespaces) else {
            didFail(withError: CustomError.emptyTextField)
            return
        }
        searchBar.resignFirstResponder()
        
        switch viewModel.getSearchType() {
        case .coffee:
            viewModel.search(with: query, region: nil)
            
        case .location:
            viewModel.search(with: query, region: mapView.region)
            
        case .general:
            viewModel.searchWithCompleter(with: query, controller: self, region: mapView.region)
            completionQuery = query
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
        viewModel.searchResults = completer.results
        viewModel.search(with: completionQuery, region: nil)
    }
}

// MARK: - UISearchResultsUpdating

extension AppleMapViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
    }
}
