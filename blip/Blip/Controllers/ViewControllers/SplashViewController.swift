//
//  SplashViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-01-07.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import RevealingSplashView

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareSplashScreen()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareSplashScreen(){
        let splash = RevealingSplashView(iconImage: UIImage(named: "Clock")!, iconInitialSize: CGSize(width: 112, height: 100), backgroundColor: #colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1))
        splash.animationType = SplashAnimationType.squeezeAndZoomOut
        splash.startAnimation(){
            print("Splash Complete")
        }
    }
}
