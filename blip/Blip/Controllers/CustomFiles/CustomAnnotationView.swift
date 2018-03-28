//
//  CustomAnnotationView.swift
//  Blip
//
//  Created by Srikanth Srinivas on 12/21/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox
//
// MGLAnnotationView subclass


class CustomAnnotationView: MGLAnnotationView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        super.isEnabled = true
//        super.cornerRadius = super.frame.size.width/2
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == "position" {
            let animation = CABasicAnimation(keyPath: event)
            animation.duration = 5.05
            return animation
        } else {
            return super.action(for: layer, forKey: event)
        }
    }

}
