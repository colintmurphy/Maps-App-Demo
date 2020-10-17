//
//  CustomMarker.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import GoogleMaps

class CustomMarker: GMSMarker {
    
    var coordinate: CLLocationCoordinate2D
    
    init(place: Shop) {
        
        coordinate = place.location.coordinates
        super.init()
        position = coordinate
        icon = UIImage(named: "coffee72")
        title = place.name
        map = nil
    }
}
