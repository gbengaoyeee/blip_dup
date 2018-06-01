//
//  navigationBarViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/12/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit

class NavigationBarViewController: UINavigationController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.backItem?.title = "Back"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
