//
//  TestNavigationViewController.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-02-01.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation

class TestNavigationViewController: NavigationViewController, NavigationViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "goToTest") as! TestVC
        // set viewcontroller properties here
        self.present(vc, animated: true, completion: nil)
        
        print("I HAVE ARRIVED BITCH")
        return true
    }

    
    

    
    

}
