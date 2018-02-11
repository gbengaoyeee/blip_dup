//
//  EndJob.swift
//  Blip
//
//  Created by Srikanth Srinivas on 1/31/18.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit

class EndJob: UIViewController {
    
    let service = ServiceCalls()
    var job: Job!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func endJobPressed(){
        
        service.endJobPressed(job: self.job)
        self.navigationController?.popToRootViewController(animated: true)
    }

}
