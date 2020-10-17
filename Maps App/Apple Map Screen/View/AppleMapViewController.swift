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
    
    // MARK: - Properties
    
    private var viewModel = AppleMapViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }
    
    lazy var locationHandler = LocationHandler(delegate: self)
    var dataSource: [MKAnnotation] = []
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        locationHandler.getUserLocation()
    }
    
    // MARK: - Map Methods
    
    private func setMapView(with location: CLLocation) {
        
        let radius = 2000.0
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        mapView.setRegion(region, animated: true)
    }
    
    private func loadCoffeeShopsInMap(with query: String) {
        
        viewModel.loadAnnotations(with: query) { annotations, error in
            if let annotations = annotations {
                self.dataSource.removeAll()
                self.dataSource.append(contentsOf: annotations)
                self.mapView.addAnnotations(self.dataSource)
                self.updateRegionWithDataSource()
            } else if let error = error {
                print(error)
            }
        }
    }
    
    private func updateRegionWithDataSource() {
        guard let region = self.viewModel.moveCameraToShow(annotations: self.dataSource) else { return }
        self.mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Setup
    
    private func setup() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
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
        
        view.image = UIImage(named: "purple-pin72")
        view.canShowCallout = true
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return view
        // MKMarkerAnnotationView vs MKAnnotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) { }
    
    private func createSelectedAnnotationView() { }
}

// MARK: - LocationHandlerDelegate

extension AppleMapViewController: LocationHandlerDelegate {
    
    func received(location: CLLocation) {
        //setMapView(with: location)
    }
    
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
        loadCoffeeShopsInMap(with: query)
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

// MARK: - AppleMapViewModelDelegate

extension AppleMapViewController: AppleViewModelProtocol {
    
    func didFinishLoad() { }
    
    func showActivity() {
        activityIndicator.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
    }
    
    func failed(with error: CustomError) { }
}
