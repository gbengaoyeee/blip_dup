//
//  GradientViewBackground.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-02-27.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Pastel

extension PastelView{

    func prepareDefaultPastelView(){
        
        let colors = [#colorLiteral(red: 0.9357799888, green: 0.4159773588, blue: 0.3661105633, alpha: 1), #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)]
        self.setColors(colors)
        self.animationDuration = 3
    }
    
    func prepareCustomPastelViewWithColors(colors: [UIColor]){
        
        self.setColors(colors)
        self.animationDuration = 3
    }

}
