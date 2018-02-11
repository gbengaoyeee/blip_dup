//
//  CustomUIButton.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/23/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit


import UIKit

class CustomUIButton: UIButton {
    
    var job: Job!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
