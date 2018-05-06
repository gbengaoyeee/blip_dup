//
//  navigationBarViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/12/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import IBAnimatable
import RevealingSplashView

class NavigationBarViewController: AnimatableNavigationController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.backItem?.title = "Back"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
    }
    
    func prepareSplash(){
        
        let splash = RevealingSplashView(iconImage: UIImage(icon: .googleMaterialDesign(.accountCircle), size: CGSize(size: 15)), iconInitialSize: CGSize(width: 112, height: 100), backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1))
        splash.animationType = SplashAnimationType.squeezeAndZoomOut
        splash.tag = 10
        self.view.addSubview(splash)
        splash.startAnimation {
            print("Splash Screen complete")
            self.appDelegate.isLaunched = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

}
