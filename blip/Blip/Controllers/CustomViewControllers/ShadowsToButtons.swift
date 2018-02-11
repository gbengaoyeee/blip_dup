//
//  File.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/2/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import UIKit


extension UIButton{
    
    func ApplyOuterShadowToButton(){
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.5)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 3
    }
    
    func ApplyCornerRadius(){
        self.layer.cornerRadius = 7
        self.clipsToBounds = true
    }
    
    func makeButtonDissapear(){
        self.alpha = 0
    }
    
    func makeButtonAppear(){
        self.alpha = 1
    }
    
}
