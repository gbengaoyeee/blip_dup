//
//  EndJob.swift
//  Blip
//
//  Created by Srikanth Srinivas on 1/31/18.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Pastel
import Lottie

class EndJob: UIViewController {
    
    @IBOutlet var gradientView: PastelView!
    
    let service = ServiceCalls()
    var job: Job!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.gradientView.startAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.gradientView.startAnimation()
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
