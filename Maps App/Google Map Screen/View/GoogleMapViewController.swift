//
//  GoogleMapViewController.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import GoogleMaps
import UIKit

//swiftlint:disable implicitly_unwrapped_optional

class GoogleMapViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
        }
    }
    
    @IBOutlet private weak var mapView: UIView!
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.hidesWhenStopped = true
        }
    }
    
    // MARK: - Properties
    
    private var googleMap: GMSMapView! {
        didSet {
            googleMap.isMyLocationEnabled = true
            googleMap.delegate = self
        }
    }
    
    private var viewModel = GoogleMapViewModel()
    private lazy var locationHandler = LocationHandler(delegate: self)
    
    // MARK: - View Life Cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if traitCollection.userInterfaceStyle == .dark {
            setDarkModeMap()
        }
    }
    
    // MARK: - UI/UX
    
    private func setup() {
        
        viewModel.delegate = self
        googleMap = GMSMapView(frame: mapView.frame)
        view.addSubview(googleMap)
        locationHandler.getUserLocation()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func setDarkModeMap() {
        do {
            guard let styleURL = Bundle.main.url(forResource: "GoogleMapDarkStyle", withExtension: "json") else { return }
            googleMap.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
        } catch {
            print(error)
        }
    }
    
    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
}

// MARK: - AppleMapViewModelDelegate

extension GoogleMapViewController: GoogleViewModelProtocol {
    
    func showActivity() {
        activityIndicator.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
    }
    
    func updateMapView() {
        guard let update = viewModel.moveCameraToShow() else { return }
        googleMap.moveCamera(update)
    }
    
    func didFinishLoad() { }
    
    func failed(with error: CustomError) {
        
        var title = "Error"
        var message = ""
        switch error {
        case .emptyTextField:
            message = "Please make sure you enter something."
            
        case .serverError, .decodingFailed:
            title = "Sorry"
            message = "It looks like we could not fetch the data."
            
        case .noLocationFound:
            title = "Sorry"
            message = "It looks like we could get your location."
        }
        showAlert(title: title, message: message) { _, _ in }
    }
}

// MARK: - LocationHandlerDelegate

extension GoogleMapViewController: LocationHandlerDelegate {
    
    func didFail(withError error: Error) {
        print(error)
    }
    
    func received(location: CLLocation) {
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 0)
        googleMap.camera = camera
    }
}

// MARK: - GMSMapViewDelegate

extension GoogleMapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        
        if let viewFromNib = Bundle.main.loadNibNamed("SelectedAnnotationView", owner: self, options: nil)?.first as? SelectedAnnotationView,
           let title = marker.title {
            
            viewFromNib.set(title: title)
            return viewFromNib
        }
        return nil
    }
}

// MARK: - UISearchBarDelegate

extension GoogleMapViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespaces) else {
            failed(with: CustomError.emptyTextField)
            return
        }
        searchBar.resignFirstResponder()
        viewModel.loadMarkers(with: query, map: googleMap)
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
