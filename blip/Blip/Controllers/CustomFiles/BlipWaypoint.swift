//
//  BlipWaypoint.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/16/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import Foundation
import MapboxDirections
import MapboxCoreNavigation

class BlipWaypoint: Waypoint{
    
    var delivery: Delivery!
    
    override init(coordinate: CLLocationCoordinate2D, coordinateAccuracy: CLLocationAccuracy, name: String?) {
        super.init(coordinate: coordinate, coordinateAccuracy: coordinateAccuracy, name: name)
    }
    override init(location: CLLocation, heading: CLHeading?, name: String?) {
        super.init(location: location, heading: heading, name: name)
    }
    
//    override init(coordinate: CLLocationCoordinate2D, coordinateAccuracy: CLLocationAccuracy, name: String?) {
//        super.init(coordinate: coordinate)
//        super.name = name
//    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
