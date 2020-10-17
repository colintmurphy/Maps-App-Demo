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
    
    private var viewModel = GoogleMapViewModel() {
        didSet {
            viewModel.delegate = self
        }
    }
    
    private lazy var locationHandler = LocationHandler(delegate: self)
    private var dataSource: [CustomMarker] = []
    
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
    
    // MARK: - Map Methods
    
    private func setMapView(with location: CLLocation) { }
    
    private func loadCoffeeShopsInMap(with query: String) {
        
        viewModel.loadMarkers(with: query) { markers, error in
            if let markers = markers {
                self.googleMap.clear()
                self.dataSource.removeAll()
                self.dataSource.append(contentsOf: markers)
                for index in 0..<self.dataSource.count {
                    self.dataSource[index].map = self.googleMap
                }
                self.updateRegionWithDataSource()
            } else if let error = error {
                print(error)
            }
        }
    }
    
    private func updateRegionWithDataSource() { }
    
    // MARK: - Setup
    
    private func setup() {
        
        googleMap = GMSMapView(frame: self.mapView.frame)
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
    
    func didFinishLoad() { }
    
    func showActivity() {
        activityIndicator.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
    }
    
    func failed(with error: CustomError) { }
}

// MARK: - LocationHandlerDelegate

extension GoogleMapViewController: LocationHandlerDelegate {
    
    func received(location: CLLocation) {
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 0)
        googleMap.camera = camera
    }
    
    func didFail(withError error: Error) {
        print(error)
    }
}

// MARK: - GMSMapViewDelegate

extension GoogleMapViewController: GMSMapViewDelegate { }

// MARK: - UISearchBarDelegate

extension GoogleMapViewController: UISearchBarDelegate {
    
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
