//
//  MainPageVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-02-27.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Pastel
import Firebase
import Material

class MainPageVC: UIViewController {
    
    @IBOutlet var gradientView: PastelView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        gradientView.startAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        gradientView.startAnimation()
    }

    
}
