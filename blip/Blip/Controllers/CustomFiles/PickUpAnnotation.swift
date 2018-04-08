//
//  PickUpAnnotation.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-07.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Mapbox

class PickUpAnnotation: MGLPointAnnotation{
    
    var photoURL: URL?
    var image:UIImage?
    var reuseIdentifier: String?
    
    var observers: NSMutableSet! = NSMutableSet()
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        super.init()
        super.coordinate = coordinate
        super.title = title
        super.subtitle = subtitle
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
