//
//  InstructionVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/20/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Firebase
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import Material

class InstructionVC: UIViewController {

    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var subInstructionLabel: UILabel!
    @IBOutlet weak var mainInstructionLabel: UILabel!
    @IBOutlet var gradientView: UIView!
    @IBOutlet weak var storeLogo: UIImageView!
    @IBOutlet weak var callButton: RaisedButton!
    @IBOutlet weak var noShowButton: RaisedButton!
    @IBOutlet weak var doneButton: RaisedButton!
    
    var subInstruction: String!
    var mainInstruction: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        prepareButtons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareView(){
        subView.ApplyCornerRadiusToView()
        subView.ApplyOuterShadowToView()
    }
    
    func prepareLabels(){
        if let text = mainInstruction{
            mainInstructionLabel.text = text
        }
        if let text = subInstruction{
            subInstructionLabel.text = text
        }
    }
    
    func prepareButtons(){
        callButton.makeCircular()
        noShowButton.makeCircular()
        doneButton.makeCircular()
        callButton.setIcon(icon: .googleMaterialDesign(.call), iconSize: CGFloat(integerLiteral: 40), color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        noShowButton.setIcon(icon: .googleMaterialDesign(.error), iconSize: CGFloat(integerLiteral: 40), color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        doneButton.setIcon(icon: .googleMaterialDesign(.check), iconSize: CGFloat(integerLiteral: 40), color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
    }

    @IBAction func noShowPressed(_ sender: Any) {
    }
    
    @IBAction func callPressed(_ sender: Any) {
    }
    
    @IBAction func donePressed(_ sender: Any) {
        let presentingVC = self.presentingViewController as? NavigationViewController
        presentingVC?.routeController.routeProgress.legIndex += 1
        presentingVC?.routeController.resume()
        self.dismiss(animated: true, completion: nil)
    }
}
