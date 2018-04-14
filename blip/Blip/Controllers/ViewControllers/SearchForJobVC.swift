//
//  SearchForJobVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/12/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation
import Material
import Pulsator
import NotificationBannerSwift

class SearchForJobVC: UIViewController {

    @IBOutlet weak var goButtonPulseAnimation: UIView!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet var map: MGLMapView!
    let pulsator = Pulsator()
    
    var gradient: CAGradientLayer!
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    let service = ServiceCalls.instance
    let userDefaults = UserDefaults.standard
    var foundJob: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMap()
        prepareBlur()
        prepareGoButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "foundJob"{
            let dest = segue.destination as! FoundJobVC
            dest.job = foundJob
        }
    }
    
    func prepareJobsNearMe(){
        
        MyAPIClient.sharedClient.getNumberOfJobsNearMe(location: self.currentLocation) { (jobNumber) in
            let leftImageView = UIImageView()
            leftImageView.setIcon(icon: .googleMaterialDesign(.info), textColor: UIColor.white, backgroundColor: UIColor.clear, size: CGSize(size: 50))
            
            let banner = NotificationBanner(title: "There are\(jobNumber)Job/s near you", subtitle: nil, leftView: leftImageView, rightView: nil, style: .info)
            banner.dismissOnSwipeUp = true
            banner.show()
        }
    }
    
    func prepareBlur(){
        
        gradient = CAGradientLayer()
        gradient.frame = map.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0.2, 0.8, 1]
        map.layer.mask = gradient
    }
    
    func prepareGoButton(){
        
        pulsator.backgroundColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
        pulsator.numPulse = 2
        pulsator.animationDuration = 3.0
        pulsator.radius = 150
        pulsator.repeatCount = .infinity
        pulsator.start()
        goButtonPulseAnimation.layer.addSublayer(pulsator)
        goButton.makeCircular()
        goButton.borderColor = UIColor.white
        goButton.layer.borderWidth = 2.5
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = map.bounds
    }
    
    @IBAction func postTestJob(_ sender: Any) {
        service.getCurrentUserInfo { (user) in
            
            let delivery1 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d1", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            let delivery2 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d2", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            let delivery3 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d3", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            self.service.addTestJob(title: "Pickup", orderer: user,  deliveries: [delivery1, delivery2, delivery3], pickupLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), earnings: 5.00, estimatedTime: 10.00)
        }
    }
    
    @IBAction func searchForJob(_ sender: Any) {
        
        service.findJob(myLocation: self.currentLocation, userHash: userDefaults.dictionary(forKey: "loginCredentials")!["emailHash"] as! String) { (job) in
            if let job = job{
                self.foundJob = job
                self.performSegue(withIdentifier: "foundJob", sender: self)
            }
        }
    }
    
}

extension SearchForJobVC: MGLMapViewDelegate{
    
    func prepareMap(){
        useCurrentLocations()
        self.map.delegate = self
        map.showsUserLocation = true
        map.showsUserHeadingIndicator = true
        map.userTrackingMode = .followWithHeading
        map.isZoomEnabled = true
        map.isScrollEnabled = false
        map.isPitchEnabled = false
        map.isRotateEnabled = true
        map.compassView.isHidden = true
    }
    
    func setMapCamera(){
        let camera = MGLMapCamera(lookingAtCenter: map.centerCoordinate, fromDistance: 4500, pitch: 15, heading: 180)
        
        // Animate the camera movement over 5 seconds.
        map.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // Substitute our custom view for the user location annotation. This custom view is defined below.
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView()
        }
        return nil
    }
}

extension SearchForJobVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        map.setCenter(locValue, zoomLevel: 7, direction: 0, animated: false)
        setMapCamera()
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
