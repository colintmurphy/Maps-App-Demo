//
//  LocationManager.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import CoreLocation
import UIKit

// MARK: - LocationHandlerDelegate

protocol LocationHandlerDelegate: AnyObject, AlertHandlerProtocol {
    
    func received(location: CLLocation)
    func didFail(withError error: Error)
}

// MARK: - LocationHandler

class LocationHandler: NSObject {
    
    // MARK: - Properties
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = true
        manager.distanceFilter = 5
        manager.showsBackgroundLocationIndicator = true
        return manager
    }()
    
    weak var delegate: LocationHandlerDelegate?
    
    // MARK: - Init
    
    init(delegate: LocationHandlerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    // MARK: - Methods
    
    func getUserLocation() {
        
        guard CLLocationManager.locationServicesEnabled() else {
            delegate?.showAlert(title: "Location Disabled", message: "Please enable your location services", buttons: [.cancel, .settings]) { _, type in
                switch type {
                case .cancel:
                    print("cancel pressed")
                    
                case .settings:
                    UIApplication.shared.openSettings()
                    
                default:
                    break
                }
            }
            return
        }
        checkAndPromptLocationAuthorization()
    }
    
    private func checkAndPromptLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            delegate?.showAlert(title: "Location Denied", message: "Please give access to your location.", buttons: [.cancel, .settings]) { _, type in
                switch type {
                case .settings:
                    UIApplication.shared.openSettings()
                    
                default:
                    break
                }
            }
            
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationHandler: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        delegate?.received(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.didFail(withError: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAndPromptLocationAuthorization()
    }
}
