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
import Mapbox
import Material
import MapboxDirections
import MapboxCoreNavigation

class OnJobVC: UIViewController {

    @IBOutlet weak var mainInsructionLabel: UILabel!
    @IBOutlet weak var subInstructionLabel: UILabel!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var callButton: RaisedButton!
    @IBOutlet weak var noShowButton: RaisedButton!
    @IBOutlet weak var doneButton: RaisedButton!
    
    let service = ServiceCalls.instance
    var waypoints:[BlipWaypoint]!
    var legIndex = 1 //1 because of origin in the first position of waypoints
    var delivery:Delivery!
    var type:String!
    var calls = 0
    let locationManager = CLLocationManager()
    var currentLocation:CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        UIApplication.shared.statusBarStyle = .lightContent
        super.viewDidLoad()
        self.delivery = waypoints[legIndex].delivery
        self.type = waypoints[legIndex].name!
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentType = waypoints[legIndex].name, let currentDelivery = waypoints[legIndex].delivery{
            prepareMap(type: currentType, delivery: currentDelivery)
            prepareInstructions(type: currentType, delivery: currentDelivery)
            prepareButtons()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareInstructions(type: String, delivery: Delivery){
        if type == "Pickup"{
            self.mainInsructionLabel.text = delivery.pickupMainInstruction
            self.subInstructionLabel.text = delivery.pickupSubInstruction
        }
        else{
            self.mainInsructionLabel.text = delivery.deliveryMainInstruction
            self.mainInsructionLabel.text = delivery.deliverySubInstruction
        }
    }
    
    func prepareButtons(){
        callButton.setIcon(icon: .googleMaterialDesign(.call), iconSize: 45, color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        noShowButton.setIcon(icon: .googleMaterialDesign(.error), iconSize: 45, color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        doneButton.setIcon(icon: .googleMaterialDesign(.done), iconSize: 45, color: UIColor.white, backgroundColor: UIColor.lightGray, forState: .normal)
        callButton.makeCircular()
        noShowButton.makeCircular()
        doneButton.makeCircular()
        doneButton.isEnabled = false
    }
    
    func activateDoneButton(){
        doneButton.backgroundColor = UIColor.green
        doneButton.isEnabled = true
    }
    
    @IBAction func googleMaps(_ sender: Any) {
        print("Before",calls)
        calls += 1
        print("After",calls)
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
        
        let popup = PopupDialog(title: "Confirm", message: "Please make sure you have successfully completed the delivery before pressing confirm. Failure to do so may result in the suspension of your account. Alternatively, press the No Show button if the delivery cannot be completed successfully")
        let confirmButton = PopupDialogButton(title: "Confirm") {
            
            self.service.completedJob(deliveryID: self.delivery.identifier, storeID: self.delivery.store.storeID, type: self.type)

            if self.waypoints.count != self.legIndex{// This is equivalent to !self.isLastWaypoint
                //increase the leg index
                self.legIndex += 1
                if let currentType = self.waypoints[self.legIndex].name, let currentDelivery = self.waypoints[self.legIndex].delivery{
                    self.prepareInstructions(type: currentType, delivery: currentDelivery)
                    self.prepareButtons()
                    self.prepareMap(type: currentType, delivery: currentDelivery)
                }
                popup.dismiss()
            }
            else{
                popup.dismiss()
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        popup.addButton(confirmButton)
        self.present(popup, animated: true, completion: nil)
    }
    
}

extension OnJobVC: MGLMapViewDelegate{
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView()
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if !(annotation is MGLUserLocation){
            let image = UIImage(named: annotation.title!!.lowercased())
            return MGLAnnotationImage(image: image!, reuseIdentifier: "annotation")
        }
        return nil
    }
    
    func prepareMap(type: String, delivery: Delivery){
        map.delegate = self
        map.showsUserLocation = true
        map.showsUserHeadingIndicator = true
        map.userTrackingMode = .followWithHeading
        let annotation = MGLPointAnnotation()
        if type == "Pickup"{
            annotation.coordinate = delivery.origin
            annotation.title = type
        }
        else{
            annotation.coordinate = delivery.deliveryLocation
            annotation.title = type
        }
        self.map.addAnnotation(annotation)
        map.setCenter(currentLocation!, zoomLevel: 7, direction: 0, animated: false)
        let camera = MGLMapCamera(lookingAtCenter: currentLocation, fromDistance: 4500, pitch: 0, heading: 0)
        map.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)) {
            if let user = self.map.userLocation{
                self.map.showAnnotations([annotation, user], animated: true)
            }
        }
    }
}

extension OnJobVC:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.type == "Pickup"{
            if let currentLocation = locations.first{
                if self.delivery.origin.distance(to: currentLocation.coordinate) < 300{
                    self.activateDoneButton()
                }
            }
        }
        else{
            if let currentLocation = locations.first{
                if self.delivery.deliveryLocation.distance(to: currentLocation.coordinate) < 300{
                    self.activateDoneButton()
                }
            }
        }
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.currentLocation = locations.first?.coordinate
    }
}
