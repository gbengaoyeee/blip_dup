//
//  JobOwnerStartJob.swift
//  Blip
//
//  Created by Srikanth Srinivas on 1/31/18.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Material
import Firebase
import Alamofire
import PopupDialog
import Pastel

class JobOwnerStartJob: UIViewController {

    @IBOutlet var gradientView: PastelView!
    
    @IBOutlet weak var StartJob: RaisedButton!
    let service = ServiceCalls()
    var job: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func StartJobPressed(_ sender: Any) {

        
        
    }
    

}
