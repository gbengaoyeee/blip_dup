//
//  BlipAnnotation.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-01-13.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox

class BlipAnnotation: NSObject, MGLAnnotation{

    // As a reimplementation of the MGLAnnotation protocol, we have to add mutable coordinate and (sub)title properties ourselves.
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    // Custom properties that we will use to customize the annotation's image.
    var job: Job?
    var photoURL: URL?
    var image:UIImage?
    var reuseIdentifier: String?
    
    var observers: NSMutableSet! = NSMutableSet()
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    override func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions = [], context: UnsafeMutableRawPointer?) {
        let observerId : String = "\(observer.hashValue)\(keyPath)"
        
        self.observers.add(observerId)
        super.addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }
    
    override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String, context: UnsafeMutableRawPointer?) {
        let observerId : String = "\(observer.hashValue)\(keyPath)"
        
        if (self.observers.contains(observerId)) {
            self.observers.remove(observerId)
            super.removeObserver(observer, forKeyPath: keyPath)
        }
    }
    
}

