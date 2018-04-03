//
//  endSignUpVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/14/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Pastel
import Material


class EndSignUp: UIViewController {
    
    @IBOutlet weak var continueButton: RaisedButton!
    @IBOutlet weak var gradientView: PastelView!
    

    override func viewDidLoad(){
        
        super.viewDidLoad()
        super.viewDidAppear(true)
        
        self.navigationController?.navigationBar.isHidden = true
        self.continueButton.ApplyCornerRadius()
        self.continueButton.ApplyOuterShadowToButton()
        gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])


        // Do any additional setup after loading the view.
    }
    @IBAction func continueButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setLoginAsRoot()
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
    
}
