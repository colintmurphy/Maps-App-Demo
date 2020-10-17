//
//  ShopResponse.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import CoreLocation

struct ShopResponse: Decodable {
    
    var shops: [Shop]
    
    enum CodingKeys: String, CodingKey {
        case shops = "candidates"
    }
}

struct Shop: Decodable {
    
    var name: String
    var location: Coordinates

    enum CodingKeys: String, CodingKey {
        case name = "address"
        case location
    }
}

struct Coordinates: Decodable {
    
    var latitude: Double
    var longitude: Double
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        
        case latitude = "y"
        case longitude = "x"
    }
}
