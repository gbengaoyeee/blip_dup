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

class FoundJobVC: UIViewController, SRCountdownTimerDelegate {

    @IBOutlet weak var pickupLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var payoutLabel: UILabel!
    @IBOutlet weak var pulseAnimationView: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var countDownView: SRCountdownTimer!
    
    var fromIndex = 0
    var toIndex = 1
    var job: Job!
    let service = ServiceCalls.instance
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var waypoints: [BlipWaypoint]!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        useCurrentLocations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareDataForNavigation()
        setupTimer()
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
        if segue.identifier == "toNavigation"{
            let dest = segue.destination as! NavigateVC
            dest.job = self.job!
            dest.waypoints = self.waypoints
        }
    }
    
    fileprivate func setupTimer(){
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func handleTimer(){
        service.putBackJobs()
        self.dismiss(animated: true, completion: nil)
        timer.invalidate()
        
    }
    
    func prepareDataForNavigation(){

        if let job = self.job{
            var distributions = ""
            for i in stride(from: 0, to: 2*job.deliveries.count, by: 1) {
                
                if i%2 != 0{
                    distributions = distributions + "\(i+1);"
                }
                else{
                    distributions = distributions + "\(i+1),"
                }
                
            }
            
            distributions = String(distributions.dropLast())
            print(distributions)
            print(job.locList)
            MyAPIClient.sharedClient.optimizeRoute(locations: job.locList, distributions: distributions) { (waypointData, routeData, error) in
                if error == nil{
                    if let waypointData = waypointData{
                        self.waypoints = self.parseDataFromOptimization(waypointData: waypointData)
                    }
                    if let routeData = routeData{
                        self.parseRouteData(routeData: routeData)
                    }
                }
                else{
                    print(error!)
                }
            }
        }
        else{
            print("Error occured. Job was nil")
            self.navigationController?.popViewController(animated: true)
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
//        self.performSegue(withIdentifier: "toNavigation", sender: self)
    }
}

extension FoundJobVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        currentLocation = locValue
        service.updateJobAccepterLocation(location: locValue)
        manager.stopUpdatingLocation()
    }
    
    func useCurrentLocations(){
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
}

extension FoundJobVC: NavigationViewControllerDelegate, VoiceControllerDelegate{
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        let vc = InstructionVC(nibName: "InstructionVC", bundle: nil)
        navigationViewController.routeController.suspendLocationUpdates()
        for way in self.waypoints{
            if waypoint.coordinate == way.coordinate{
                vc.isLastWaypoint = (self.waypoints.last == way)
                print("Arrived at waypoint")
                if let name = way.name{
                    if name == "Pickup"{
                        vc.mainInstruction = way.delivery.pickupMainInstruction
                        vc.subInstruction = way.delivery.pickupSubInstruction
                    }
                    else if name == "Delivery"{
                        vc.mainInstruction = way.delivery.deliveryMainInstruction
                        vc.subInstruction = way.delivery.deliverySubInstruction
                    }
                }
                navigationViewController.present(vc, animated: true, completion: nil)
            }
        }
        return false
    }
    
    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        let waypoint = self.getWaypointFor(coordinate: annotation.coordinate)
        if let name = waypoint.name{
            if name == "Pickup"{
                return CustomPickupAnnotationView()
            }
            else if name == "Delivery"{
                return CustomDropOffAnnotationView()
            }
        }
        return nil
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let x = MGLCircleStyleLayer(identifier: identifier, source: source)
        x.circleColor = MGLStyleValue.init(rawValue: .cyan)
        x.circleRadius = MGLStyleValue.init(rawValue: 15)
        return x
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let x = MGLSymbolStyleLayer.init(identifier: identifier, source: source)
        x.text = MGLStyleValue.init(rawValue: "ya")
        return x
    }
    
    
    
    func navigationViewControllerDidCancelNavigation(_ navigationViewController: NavigationViewController) {
        
        // DO THIS WHEN YOU CANCEL THE NAVIGATION IT HAS TO PUT BACK JOBS IN THE ALLJOBS REF AND REMOVE FROM USER REF
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension FoundJobVC{
    
    func call(number: String!)  {
        let url: NSURL = URL(string: "Tel:\(number)")! as NSURL
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    func parseDataFromOptimization(waypointData: [[String: AnyObject]]) -> [BlipWaypoint]{
        var waypointList = [BlipWaypoint]()
        var i = 0
        while waypointList.count < (waypointData.count){
            for element in waypointData{
//                let location = CLLocationCoordinate2D(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let location_one = CLLocationCoordinate2D(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let location_two = CLLocationCoordinate2D(latitude: (element["location"]! as! [Double])[1]+1, longitude: (element["location"]! as! [Double])[0]+2)
//                let waypoint = Waypoint(coordinate: location)
                let loc = CLLocation(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let way = BlipWaypoint(location: loc, heading: nil, name: nil)
                way.delivery = Delivery(deliveryLocation: location_one, identifier: "identifier", origin: location_two, recieverName: "receiverName", recieverNumber: "receiverNumber", pickupMainInstruction: "pickupMainInstruction", pickupSubInstruction: "pickupSubInstruction", deliveryMainInstruction: "deliveryMainInstruction", deliverySubInstruction: "deliverySubInstruction")
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
            if index == 0{
                way.name = "Origin"
            }
            else if index%2 == 0{
                way.name = "Delivery"
            }
            else{
                way.name = "Pickup"
            }
            print(way.name!)
            print(way.delivery)
            print(way.delivery.deliverySubInstruction)
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
                    
                    self.present(navigation, animated: true, completion: nil)
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
            
            if let name = waypoint.name{
                if name == "Pickup"{
                    if dist > delivery.origin.distance(to: waypoint.coordinate){
                        dist = delivery.origin.distance(to: waypoint.coordinate)
                        index = i
                    }
                }
                else if name == "Delivery"{
                    if dist > delivery.deliveryLocation.distance(to: waypoint.coordinate){
                        dist = delivery.deliveryLocation.distance(to: waypoint.coordinate)
                        index = i
                    }
                }
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
        timeLabel.text = "Estimated time: \(minutes.rounded()) min"
    }
}