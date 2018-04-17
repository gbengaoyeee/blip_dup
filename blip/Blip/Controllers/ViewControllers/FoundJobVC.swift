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

class FoundJobVC: UIViewController, SRCountdownTimerDelegate {

    @IBOutlet weak var pickupLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var payoutLabel: UILabel!
    @IBOutlet weak var pulseAnimationView: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var countDownView: SRCountdownTimer!
    
    var job: Job!
    let service = ServiceCalls.instance
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var waypoints: [Waypoint]!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        useCurrentLocations()
        prepareCenterView()
        prepareMap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareDataForNavigation()
        setupTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    fileprivate func setupTimer(){
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func handleTimer(){
        service.putBackJob()
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
        map.clipsToBounds = true
        let camera = MGLMapCamera(lookingAtCenter: (job.deliveries.first?.origin)!, fromDistance: 6000, pitch: 0, heading: 0)
        map.setCamera(camera, animated: true)
        let pickupAnnotation = MGLPointAnnotation()
        pickupAnnotation.coordinate = camera.centerCoordinate
        map.addAnnotation(pickupAnnotation)
    }
    
    func prepareCenterView(){
        let pulsator = Pulsator()
        pulsator.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
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
        calculateAndPresentNavigation(waypointList: self.waypoints)
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

extension FoundJobVC: NavigationViewControllerDelegate{
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        
        if let name = waypoint.name{
            if name == "Pickup"{
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WaypointArrivalVC") as! WaypointArrivalVC
                navigationViewController.present(vc, animated: true, completion: nil)
                return true
            }
        }
        return false
    }
}

extension FoundJobVC{
    
    func parseDataFromOptimization(waypointData: [[String: AnyObject]]) -> [Waypoint]{
        
        var waypointList = [Waypoint]()
        var i = 0
        while waypointList.count < (waypointData.count){
            for element in waypointData{
                let location = CLLocationCoordinate2D(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let waypoint = Waypoint(coordinate: location)
                if element["waypoint_index"] as? Int == i{
                    waypointList.append(waypoint)
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
        }
        
        return waypointList
    }
    
    func calculateAndPresentNavigation(waypointList: [Waypoint]){
        
        let options = NavigationRouteOptions(waypoints: waypointList, profileIdentifier: .automobile)
        _ = Directions.shared.calculate(options, completionHandler: { (waypoints, routes, error) in
            if error == nil{
                let navigation = NavigationViewController(for: (routes?.first)!)
                navigation.mapView?.styleURL = URL(string:"mapbox://styles/srikanthsrnvs/cjd6ciwwm54my2rms3052j5us")
                let x = SimulatedLocationManager(route: (routes?.first)!)
                x.speedMultiplier = 3.0
                navigation.routeController.locationManager = x
                navigation.delegate = self
                self.present(navigation, animated: true, completion: nil)
            }
            else{
                print(error!)
            }
        })
    }
    
    func parseRouteData(routeData: [String: AnyObject]){
        
        let estimatedTime = routeData["duration"] as! NSNumber
        let minutes = estimatedTime.doubleValue/60
        timeLabel.text = "Estimated time: \(minutes.rounded()) min"
    }
}
