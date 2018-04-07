//
//  CustomMGLAnnotation.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-01-13.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox

class CustomMGLAnnotation: MGLPointAnnotation{

    var job: Job?
    var photoURL: URL?
    
    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    } 
    
}

