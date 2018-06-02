//
//  OnJobVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-06-02.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import MapKit
import PopupDialog
import CoreLocation

class OnJobVC: UIViewController {

    @IBOutlet weak var mainInsructionLabel: UILabel!
    @IBOutlet weak var subInstructionLabel: UILabel!
    let service = ServiceCalls.instance
    var waypoints:[BlipWaypoint]!
    var legIndex = 1 //1 because of origin in the first position of waypoints
    var delivery:Delivery!
    var type:String!
    var calls = 0
    let locationManager = CLLocationManager()
    var currentLocation:CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        print("WAYPOINT", self.waypoints)
        // Do any additional setup after loading the view.
        if waypoints != nil{
            self.delivery = waypoints[legIndex].delivery
            self.type = waypoints[legIndex].name
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func googleMaps(_ sender: Any) {
        
    }
    
    @IBAction func appleMapsPressed(_ sender: Any) {
        let location = self.delivery.deliveryLocation
        let regionDistance:CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegionMakeWithDistance(location!, regionDistance, regionDistance)
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span) ]
        let placemark = MKPlacemark(coordinate: location!)
        let mapItem = MKMapItem(placemark: placemark)
        //Set mapItem name here which is also name of location
        mapItem.openInMaps(launchOptions: options)
        
    }
    
    @IBAction func callButton(_ sender: Any) {
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
    
    @IBAction func checkMarkPressed(_ sender: Any) {
        if self.currentLocation != self.delivery.deliveryLocation{//checks if the user is in the pickup/delivery location
            //To- do : not yet in the place
            print("NOT IN YOUR PICKUP/DELIVERY LOCATION")
            return
        }
        
        let popup = PopupDialog(title: "Confirm", message: "Please make sure you have successfully completed the delivery before pressing confirm. Failure to do so may result in the suspension of your account. Alternatively, press the No Show button if the delivery cannot be completed successfully")
        let confirmButton = PopupDialogButton(title: "Confirm") {
            
            self.service.completedJob(deliveryID: self.delivery.identifier, storeID: self.delivery.store.storeID, type: self.type)
            
//            if !self.isLastWaypoint{
            if self.waypoints.count != self.legIndex{// This is equivalent to !self.isLastWaypoint
                self.legIndex += 1
                //Do other things here when the check mark is pressed and its the last waypoint
                //like animate the sub and main instructions
                popup.dismiss()
            }
            else{
                popup.dismiss()
                self.dismiss(animated: true, completion: {
                    //All trips have been made
                })
            }
        }
        popup.addButton(confirmButton)
        self.present(popup, animated: true, completion: nil)
    }
    
}


extension OnJobVC:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.currentLocation = locValue
    }
}
