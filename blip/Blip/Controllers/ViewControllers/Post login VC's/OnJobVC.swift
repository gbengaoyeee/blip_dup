//
//  OnJobVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-06-02.
//  Copyright © 2018 Blip. All rights reserved.

import UIKit
import MapKit
import PopupDialog
import CoreLocation
import Mapbox
import Material
import MapboxDirections
import MapboxCoreNavigation
import SwipeCellKit

class OnJobVC: UIViewController {

    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var waypointTableView: UITableView!
    
    let service = ServiceCalls.instance
    var waypoints:[BlipWaypoint]!
    var legIndex = 0
    var delivery:Delivery!
    var type:String!
    let locationManager = CLLocationManager()
    var currentLocation:CLLocationCoordinate2D!
    var distance = 1000
    var distanceToEvent: Double!
    
    override func viewDidLoad() {

        super.viewDidLoad()
        prepareWaypointData()
        prepareLocationUsage()
        prepareTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentType = waypoints[legIndex].name, let currentDelivery = waypoints[legIndex].delivery{
            prepareMap(type: currentType, delivery: currentDelivery)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func prepareWaypointData(){
        waypoints.remove(at: 0)
        self.delivery = waypoints[legIndex].delivery
        self.type = waypoints[legIndex].name!
    }
    
    func prepareLocationUsage(){
        
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
    
//    @IBAction func noShowPressed(_ sender: Any) {
//        if type == "Delivery" || type == "Pickup"{
//            let alert = PopupDialog(title: "No Show", message: "Press continue if you cannot contact the person to complete the \(type.lowercased()). Please wait up to 5 mins before pressing this button. Doing so without waiting or making an effort to call/contact the person may result in a suspension of your account")
//            let cancel = PopupDialogButton(title: "Cancel") {
//                alert.dismiss()
//            }
//            let continueButton = PopupDialogButton(title: "Continue") {
//                if self.calls != 0{
//                    self.service.addNoShow(id: self.delivery.identifier, call: true)
//                }
//                else{
//                    self.service.addNoShow(id: self.delivery.identifier, call: false)
//                }
//            }
//            alert.addButtons([cancel, continueButton])
//            self.present(alert, animated: true, completion: nil)
//        }
//    }
    
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
        if let annotations = map.annotations{
            map.removeAnnotations(annotations)
        }
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
    
    func displayCompletionError(){
        let popup = PopupDialog(title: "Error", message: "You have not arrived at the target point yet!")
        self.present(popup, animated: true, completion: nil)
    }
    
    func completeJob(forCellAt: IndexPath){
        let popup = PopupDialog(title: "Confirm", message: "Please make sure you have successfully completed the delivery before pressing confirm. Failure to do so may result in the suspension of your account. Alternatively, press the No Show button if the delivery cannot be completed successfully")
        let confirmButton = PopupDialogButton(title: "Confirm") {
            
            self.service.completedJob(deliveryID: self.delivery.identifier, storeID: self.delivery.store.storeID, type: self.type)
            self.waypoints.remove(at: forCellAt.row)
            self.waypointTableView.deleteRows(at: [forCellAt], with: .left)
            if self.waypoints.count != self.legIndex{
                
                self.type = self.waypoints[self.legIndex].name!
                self.delivery = self.waypoints[self.legIndex].delivery
                if let currentType = self.waypoints[self.legIndex].name, let currentDelivery = self.waypoints[self.legIndex].delivery{
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
        
        if Int(distanceToEvent) > distance{
            self.displayCompletionError()
        }
        else{
            self.present(popup, animated: true, completion: nil)
        }
    }
}

extension OnJobVC:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.type == "Pickup"{
            if let currentLocation = locations.first{
                self.distanceToEvent = self.delivery.origin.distance(to: currentLocation.coordinate)
            }
        }
        else{
            if let currentLocation = locations.first{
                self.distanceToEvent = self.delivery.deliveryLocation.distance(to: currentLocation.coordinate)
            }
        }
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.currentLocation = locations.first?.coordinate
    }
}

extension OnJobVC: UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! WaypointCell
        cell.selectionStyle = .none
        prepareMap(type: cell.type, delivery: cell.delivery)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {
            return nil
        }
        if indexPath.row == 0{
            let doneAction = SwipeAction(style: .destructive, title: "Complete") { (action, index) in
                self.completeJob(forCellAt: index)
            }
            doneAction.backgroundColor = #colorLiteral(red: 0, green: 0.7973585725, blue: 0, alpha: 1)
            doneAction.title = "Complete"
            doneAction.image = UIImage(icon: .googleMaterialDesign(.done), size: CGSize(size: 40), textColor: UIColor.white, backgroundColor: UIColor.clear)
            return [doneAction]
        }
        else{
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
    
    func prepareTableView(){
        waypointTableView.delegate = self
        waypointTableView.dataSource = self
        waypointTableView.rowHeight = UITableViewAutomaticDimension
        waypointTableView.estimatedRowHeight = 200
        waypointTableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.waypoints.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = waypointTableView.dequeueReusableCell(withIdentifier: "waypointCell") as! WaypointCell
        cell.delegate = self
        cell.type = waypoints[indexPath.row].name
        cell.delivery = waypoints[indexPath.row].delivery
        cell.prepareCell()
        return cell
    }
}
















