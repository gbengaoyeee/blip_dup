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
import PopupDialog
import Kingfisher

class InstructionVC: UIViewController {

    @IBOutlet weak var subInstructionLabel: UILabel!
    @IBOutlet weak var mainInstructionLabel: UILabel!
    @IBOutlet weak var storeLogo: UIImageView!
    @IBOutlet weak var callButton: RaisedButton!
    @IBOutlet weak var noShowButton: RaisedButton!
    @IBOutlet weak var doneButton: RaisedButton!
    
    var navViewController: NavigationViewController!
    var type: String!
    var delivery: Delivery!
    let service = ServiceCalls.instance
    var subInstruction: String!
    var mainInstruction: String!
    var isLastWaypoint: Bool!
    var storeLogoURL: String!
    var phoneNumber: URL!
    var calls = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        prepareButtons()
        prepareLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func prepareView(){
        storeLogo.makeCircular()
        view.ApplyCornerRadiusToView()
        view.ApplyOuterShadowToView()
    }
    
    func prepareLabels(){
        if let text = mainInstruction{
            mainInstructionLabel.text = text
        }
        if let text = subInstruction{
            subInstructionLabel.text = text
        }
        if let url = delivery.store.storeLogo{
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { (image, error, cache, url) in
                if let image = image{
                    self.storeLogo.image = image
                }
            }
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
        if type == "Delivery" || type == "Pickup"{
            let alert = PopupDialog(title: "No Show", message: "Press continue if you cannot contact the person to complete the \(type.lowercased()). Please wait up to 5 mins before pressing this button. Doing so without waiting or making an effort to call/contact the person may result in a suspension of your account")
            let cancel = PopupDialogButton(title: "Cancel") {
                alert.dismiss()
            }
            let continueButton = PopupDialogButton(title: "Continue") {
                if self.calls != 0{
                    self.service.addNoShow(id: self.delivery.identifier, call: true)
                }
                else{
                    self.service.addNoShow(id: self.delivery.identifier, call: false)
                }
            }
            alert.addButtons([cancel, continueButton])
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func callPressed(_ sender: Any) {
        if type == "Pickup"{
            if let url:URL = URL(string: "tel://\(self.delivery.pickupNumber!)"), UIApplication.shared.canOpenURL(url){
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                calls += 1
            }
        }
        else{
            if let url:URL = URL(string: "tel://\(self.delivery.receiverPhoneNumber!)"), UIApplication.shared.canOpenURL(url){
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                calls += 1
            }
        }
    }
    
    @IBAction func donePressed(_ sender: Any) {
        let popup = PopupDialog(title: "Confirm", message: "Please make sure you have successfully completed the delivery before pressing confirm. Failure to do so may result in the suspension of your account. Alternatively, press the No Show button if the delivery cannot be completed successfully")
        let confirmButton = PopupDialogButton(title: "Confirm") {
            print("DISMISSED")
            
            self.service.completedJob(deliveryID: self.delivery.identifier, storeID: self.delivery.store.storeID, type: self.type)
            
            if !self.isLastWaypoint{
                self.navViewController?.routeController.routeProgress.legIndex += 1
                self.navViewController?.routeController.resume()
                popup.dismiss()
                self.dismiss(animated: true, completion: nil)
            }
            else{
                popup.dismiss()
                self.performSegue(withIdentifier: "unwindToRoot", sender: self)
            }
        }
        popup.addButton(confirmButton)
        self.present(popup, animated: true, completion: nil)
        
    }
}
