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
    
    var type: String!
    var delivery: Delivery!
    let service = ServiceCalls.instance
    var subInstruction: String!
    var mainInstruction: String!
    var isLastWaypoint: Bool!
    var storeLogoURL: String!
    var phoneNumber: URL!
    
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
        if let url = storeLogoURL{
            storeLogo.kf.setImage(with: URL(string: url))
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
        // WHen you press this, set the delivery reference this controller is associated with to noShow: True in firebase
        //it might be weird what u see in firebase but that happens because of the sample delivery object being set in FoundJobVC
        service.addNoShow(id: self.delivery.identifier)
    }
    
    @IBAction func callPressed(_ sender: Any) {
        //CAll the number associated with this delivery object. First check type. If type is pickup, call delivery.pickupNumber, if type is delivery, call delivery.reciverNumber. Type is a string. self.type == Delivery or Pickup
        if let url:URL = URL(string: "tel://\(self.delivery.receiverPhoneNumber!)"), UIApplication.shared.canOpenURL(url){
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func donePressed(_ sender: Any) {
        let presentingVC = self.presentingViewController as? NavigationViewController
        if !isLastWaypoint{
            presentingVC?.routeController.routeProgress.legIndex += 1
            presentingVC?.routeController.resume()
            self.dismiss(animated: true, completion: nil)
        }
        else{
            self.prepareAndAddBlurredLoader()
            service.completeJob {
                self.removedBlurredLoader()
                self.presentingViewController?.presentingViewController?.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
