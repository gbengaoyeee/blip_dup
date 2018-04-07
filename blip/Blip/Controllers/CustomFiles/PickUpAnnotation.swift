//
//  PickUpAnnotation.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-07.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Mapbox

class PickUpAnnotation: BlipAnnotation{
    
    override init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        super.init(coordinate: coordinate, title: title, subtitle: subtitle)
        
    }
}
