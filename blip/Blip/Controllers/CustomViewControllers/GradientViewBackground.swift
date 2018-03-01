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
        
        let colors = [#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)]
        self.setColors(colors)
        self.animationDuration = 3
    }
    
    func prepareCustomPastelViewWithColors(colors: [UIColor]){
        
        self.setColors(colors)
        self.animationDuration = 3
    }

}
