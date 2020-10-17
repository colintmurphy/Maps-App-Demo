//
//  GeocoderHandler.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import MapKit

protocol GeocoderHandler {
    func geocoding(query: String, completion: @escaping (CLLocation?, CustomError?) -> Void)
}

extension GeocoderHandler {
    func geocoding(query: String, completion: @escaping (CLLocation?, CustomError?) -> Void) {
        
        CLGeocoder().geocodeAddressString(query) { placemarks, _ in
            if let placemarks = placemarks,
               let location = placemarks.first?.location {
                completion(location, nil)
            } else {
                completion(nil, CustomError.noLocationFound)
            }
        }
    }
}
