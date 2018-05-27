//
//  FoundJobVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/13/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Firebase
import Mapbox
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import SRCountdownTimer
import Pulsator
import PopupDialog
import NotificationBannerSwift
import Material

class FoundJobVC: UIViewController, SRCountdownTimerDelegate {

    @IBOutlet weak var pickupLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var pulseAnimationView: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var countDownView: SRCountdownTimer!
    @IBOutlet weak var acceptJob: RaisedButton!
    
    var fromIndex = 0
    var toIndex = 1
    var job: Job!
    var service:ServiceCalls! = ServiceCalls.instance
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var waypoints: [BlipWaypoint]!
    var timer = Timer()
    var mglSource: MGLShapeSource!
    
    var currentType: String!
    var currentSubInstruction: String!
    var currentMainInstruction: String!
    var currentDelivery: Delivery!
    var isLastWaypoint: Bool!
    var navViewController: NavigationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        acceptJob.isUserInteractionEnabled = false
        prepareDataForNavigation { (bool) in
            if bool{
                self.acceptJob.isUserInteractionEnabled = true
            }else{
                self.preparePopupForErrors()
            }
        }
        setupTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        service.removeFirebaseObservers()
    }
    
    override func viewDidLayoutSubviews() {
        prepareCenterView()
        prepareMap()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentInstructions"{
            let dest = segue.destination as! InstructionVC
            dest.delivery = self.currentDelivery
            dest.subInstruction = self.currentSubInstruction
            dest.mainInstruction = self.currentMainInstruction
            dest.type = self.currentType
            dest.isLastWaypoint = self.isLastWaypoint
            dest.navViewController = self.navViewController
        }
    }
    
    fileprivate func setupTimer(){
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func handleTimer(){
        service.putBackJobs()
        timer.invalidate()
        self.navigationController?.popViewController(animated: true)
    }
    
    func preparePopupForErrors(){
        let popup = PopupDialog(title: "Error", message: "An error occured when parsing job data")
        let okButton = PopupDialogButton(title: "Continue") {
            popup.dismiss()
            self.navigationController?.popToRootViewController(animated: true)
        }
        popup.addButton(okButton)
    }
    
    func prepareDataForNavigation(completion: @escaping(Bool) -> ()){
        if let job = self.job{

            var distributions = ""
            for i in stride(from: 0, to: 2*(job.deliveries.count - job.getUnfinishedDeliveries().count), by: 1) {
                
                if i%2 != 0{
                    distributions = distributions + "\(i+1);"
                }
                else{
                    distributions = distributions + "\(i+1),"
                }
            }
            distributions = String(distributions.dropLast())
            MyAPIClient.sharedClient.optimizeRoute(locations: job.locList, distributions: distributions) { (waypointData, routeData, error) in
                if error == nil{
                    if let waypointData = waypointData{
                        self.waypoints = self.parseDataFromOptimization(waypointData: waypointData)
                    }
                    if let routeData = routeData{
                        self.parseRouteData(routeData: routeData)
                    }
                    completion(true)
                }
                else{
                    completion(false)
                    print(error!)
                    self.service.putBackJobs()
                }
            }
        }
        else{
            completion(false)
            print("An Error occured. No Job was passed")
        }
    }
    
    func prepareMap(){
        map.makeCircular()
        let camera = MGLMapCamera(lookingAtCenter: (job.deliveries.first?.origin)!, fromDistance: 6000, pitch: 0, heading: 0)
        map.setCamera(camera, animated: true)
        let pickupAnnotation = MGLPointAnnotation()
        pickupAnnotation.coordinate = camera.centerCoordinate
        map.addAnnotation(pickupAnnotation)
    }
    
    func prepareCenterView(){
        let pulsator = Pulsator()
        pulsator.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        pulsator.numPulse = 4
        pulsator.animationDuration = 4
        pulsator.radius = 400
        pulsator.repeatCount = .infinity
        pulsator.start()
        pulseAnimationView.layer.addSublayer(pulsator)
        countDownView.makeCircular()
        countDownView.clipsToBounds = true
        countDownView.start(beginingValue: 30)
    }
    
    @IBAction func acceptJobPressed(_ sender: Any) {
        timer.invalidate()
        calculateAndPresentNavigation(waypointList: self.waypoints, present: true)
    }
}

extension FoundJobVC: MGLMapViewDelegate{
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let delivery = UIImage(named: "delivery")
        if let delivery = delivery{
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(size: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
}

extension FoundJobVC: NavigationViewControllerDelegate, VoiceControllerDelegate{
    
    func navigationViewController(_ viewController: NavigationViewController, didSend feedbackId: String, feedbackType: FeedbackType) {
        if feedbackType == .mapIssue{
            let error = PopupDialog(title: "We want to know whats wrong", message: "Get in touch with us right now at 647-983-9837, and mention your email address")
            let callButton = PopupDialogButton(title: "Call") {
                if let url:URL = URL(string: "tel://6479839837"), UIApplication.shared.canOpenURL(url){
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
            error.addButton(callButton)
            self.present(error, animated: true)
        }
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {

        self.navViewController = navigationViewController
        navigationViewController.routeController.suspendLocationUpdates()
        for way in self.waypoints{
            if waypoint.coordinate == way.coordinate{
                self.isLastWaypoint = (self.waypoints.last?.coordinate == way.coordinate)
                self.currentDelivery = way.delivery
                if let name = way.name{
                    if name == "Pickup"{
                        self.currentType = "Pickup"
                        self.currentMainInstruction = way.delivery.pickupMainInstruction
                        self.currentSubInstruction = way.delivery.pickupSubInstruction
                    }
                    else if name == "Delivery"{
                        self.currentType = "Delivery"
                        self.currentMainInstruction = way.delivery.deliveryMainInstruction
                        self.currentSubInstruction = way.delivery.deliverySubInstruction
                    }
                }
                self.performSegue(withIdentifier: "presentInstructions", sender: self)
            }
        }
        return false
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {

        var features = [MGLPointFeature]()
        for waypoint in self.waypoints {
            let feature = MGLPointFeature()
            feature.coordinate = waypoint.coordinate
            if let name = waypoint.name{
                if name == "Pickup" || name == "Delivery"{
                    feature.attributes = ["type": name.lowercased()]
                    features.append(feature)
                }
            }
        }
        
        let deliveryImage = UIImage(named: "delivery")
        let pickupImage = UIImage(named: "pickup")
        let y = MGLShapeSource(identifier: "waypointLayer", features: features, options: nil)
        mglSource = y
        mapView.style?.addSource(mglSource)
        mapView.style?.setImage(deliveryImage!.resizeImage(targetSize: CGSize(size: 40)), forName: "delivery")
        mapView.style?.setImage(pickupImage!.resizeImage(targetSize: CGSize(size: 40)), forName: "pickup")
        let x = MGLSymbolStyleLayer(identifier: "waypointLayer", source: mglSource)
        x.iconImageName = NSExpression(forKeyPath: "type")
        x.iconAllowsOverlap = NSExpression(forConstantValue: true)
        x.iconIgnoresPlacement = NSExpression(forConstantValue: true)

        return x
    }
    
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let delivery = UIImage(named: "delivery")
        if let delivery = delivery{
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(size: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
    
    func navigationViewControllerDidEndNavigation(_ navigationViewController: NavigationViewController, cancelled: Bool) {
        let alertPopup = PopupDialog(title: "Warning", message: "Are you sure you wish to cancel the job you are currently on? Taking a job and cancelling midway may result in a suspension of your account.")
        let yesButton = PopupDialogButton(title: "Yes") {
            alertPopup.dismiss()
            self.service.userCancelledJob()
            self.navigationController?.popToRootViewController(animated: true)
        }
        let noButton = PopupDialogButton(title: "No") {
            alertPopup.dismiss()
            navigationViewController.routeController.resume()
        }
        alertPopup.addButtons([yesButton, noButton])
        navigationViewController.present(alertPopup, animated: true, completion: nil)
    }
}

extension FoundJobVC{
    
    func parseDataFromOptimization(waypointData: [[String: AnyObject]]) -> [BlipWaypoint]{
        var waypointList = [BlipWaypoint]()
        var i = 0
        while waypointList.count < (waypointData.count){
            for element in waypointData{

                let loc = CLLocation(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let way = BlipWaypoint(location: loc, heading: nil, name: nil)
                if element["waypoint_index"] as? Int == i{
                    waypointList.append(way)
                    i += 1
                }
            }
        }
        for way in waypointList{
            
            var dist: Double! = 20000
            var index: Int!
            for loc in job.locList{
                
                if dist > loc.distance(to: way.coordinate){
                    dist = loc.distance(to: way.coordinate)
                    index = job.locList.index(of: loc)
                }
            }
            way.delivery = getDeliveryFor(waypoint: way)
            if way.delivery.state != nil{
                way.name = "Delivery"
            }
            else{
                if index == 0{
                    way.name = "Origin"
                }
                else if index%2 == 0{
                    way.name = "Delivery"
                }
                else{
                    way.name = "Pickup"
                }
            }
        }
        return waypointList
    }
    

    func getWaypointFor(coordinate: CLLocationCoordinate2D) -> BlipWaypoint{
        
        var dist: Double! = 20000
        var index: Int!
        var i = 0
        for waypoint in self.waypoints{
            if dist > waypoint.coordinate.distance(to: coordinate){
                dist = waypoint.coordinate.distance(to: coordinate)
                index = i
            }
            i += 1
        }
        return self.waypoints[index]
    }
    
    func calculateAndPresentNavigation(waypointList: [BlipWaypoint], present: Bool){
        
        let options = NavigationRouteOptions(waypoints: waypointList, profileIdentifier: .automobile)
        _ = Directions.shared.calculate(options, completionHandler: { (waypoints, routes, error) in
            if error == nil{
                if present{
                    let navigation = NavigationViewController(for: (routes?.first)!)
                    navigation.mapView?.styleURL = URL(string:"mapbox://styles/srikanthsrnvs/cjd6ciwwm54my2rms3052j5us")
                    let x = SimulatedLocationManager(route: (routes?.first)!)
                    x.speedMultiplier = 3.0
                    navigation.routeController.locationManager = x
                    navigation.delegate = self
                    navigation.showsEndOfRouteFeedback = false
                    self.service.setIsTakenOnGivenJobsAndStore(waypointList: waypointList)
                    self.navigationController?.pushViewController(navigation, animated: true)
                }
            }
            else{
                print(error!)
            }
        })
    }
    
    func getDeliveryFor(waypoint: Waypoint) -> Delivery?{
        var dist: Double! = 20000
        var index: Int!
        var i = 0
        for delivery in job.deliveries{
            
            if dist > min(delivery.origin.distance(to: waypoint.coordinate), (delivery.origin.distance(to: waypoint.coordinate))){
                dist = min(delivery.origin.distance(to: waypoint.coordinate), (delivery.origin.distance(to: waypoint.coordinate)))
                index = i
            }
            i += 1
        }
        if let index = index{
            return job.deliveries[index]
        }
        return nil
    }
    
    func instructionsUponArrivalAt(waypoint: Waypoint) -> [String]?{
        if let delivery = getDeliveryFor(waypoint: waypoint){
            if let name = waypoint.name{
                if name == "Pickup"{
                    return [delivery.pickupMainInstruction, delivery.pickupSubInstruction]
                }
                else if name == "Delivery"{
                    return [delivery.deliveryMainInstruction, delivery.deliverySubInstruction]
                }
            }
        }
        return nil
    }
    
    func parseRouteData(routeData: [String: AnyObject]){
        let estimatedTime = routeData["duration"] as! NSNumber
        let minutes = estimatedTime.doubleValue/60
        timeLabel.text = "\(minutes.rounded()) min(s)"
        pickupLabel.text = "\(job.deliveries.count) Delivery(s)"
    }
}





