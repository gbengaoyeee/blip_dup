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
import Lottie

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
        prepareBlur()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        prepareMap()
        prepareGoButton()
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCurrentDevice()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //ERASE YOUR service.removeFirebaseObservers HERE IF IT STILL HERE
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateCurrentDevice(){
        service.updateCurrentDeviceToken()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "foundJob"{
            let dest = segue.destination as! FoundJobVC
            dest.job = foundJob
        }
    }
    
    fileprivate func showBanner(title: String, subtitle: String?, style:BannerStyle){
        let leftImageView = UIImageView()
        leftImageView.setIcon(icon: .googleMaterialDesign(.info), textColor: UIColor.white, backgroundColor: UIColor.clear, size: CGSize(size: 50))
        let banner = NotificationBanner(title: title, subtitle: subtitle, leftView: leftImageView, rightView: nil, style: style)
        banner.dismissOnSwipeUp = true
        banner.show()
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
            
            self.service.addTestJob(deliveryLocation: (self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000)), pickupLocation: (self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 3000)), recieverName: "Srikanth Srinivas", recieverNumber: "6478229867", pickupMainInstruction: "Pickup from xyz", pickupSubInstruction: "Go to front entrance of xyz, order number 110021 is waiting for you", deliveryMainInstruction: "Deliver to Srikanth Srinivas", deliverySubInstruction: "Go to main entrace, and buzz code 2003", pickupNumber: "6479839837")
        }
    }
    
    @IBAction func searchForJob(_ sender: Any) {

        goButton.isUserInteractionEnabled = false
        let leftImageView = UIView()
        let loading = LOTAnimationView(name: "loading")
        loading.loopAnimation = true
        leftImageView.handledAnimation(Animation: loading, width: 1, height: 1)
        let banner = NotificationBanner(title: "Please wait", subtitle: "Looking for job", leftView: leftImageView, rightView: nil, style: .info)
        banner.dismissOnSwipeUp = false
        banner.show()
        loading.play()
        
        self.service.findJob(myLocation: self.currentLocation, userHash: self.userDefaults.dictionary(forKey: "loginCredentials")!["emailHash"] as! String) { (errorCode, job) in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                banner.dismiss()
                loading.stop()
                if let job = job{
                    self.foundJob = job
                    self.goButton.isUserInteractionEnabled = true
                    self.performSegue(withIdentifier: "foundJob", sender: self)
                }
                if errorCode != nil{
                    if errorCode == 400{
                        //Not verified
                        self.showBanner(title: "Account Not Verified", subtitle: "Please contact us to verify your account", style: .warning)
                        print("Not verified")
                    }
                    else if errorCode == 500{
                        //Flagged
                        self.showBanner(title: "Error", subtitle: "Your account has been disabled due to leaving a job. Please contact us to unlock your account", style: .warning)
                        print("Flagged")
                    }else{
                        // No job Found
                        let newBanner = NotificationBanner(title: "Error", subtitle: "No job found at this time", style: .info)
                        newBanner.autoDismiss = true
                        newBanner.show()
                        newBanner.dismissOnSwipeUp = true
                        newBanner.dismissOnTap = true
                        print("No job Found")
                    }
                    self.goButton.isUserInteractionEnabled = true
                    return
                }
            })
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
        map.compassView.isHidden = true
    }
    
    func setMapCamera(){
        map.setCenter(currentLocation, zoomLevel: 7, direction: 0, animated: false)
        let camera = MGLMapCamera(lookingAtCenter: currentLocation, fromDistance: 4500, pitch: 0, heading: 0)
        map.setCamera(camera, withDuration: 3, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)) {
            self.service.loadMapAnnotations(map: self.map)
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // Substitute our custom view for the user location annotation. This custom view is defined below.
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView()
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let delivery = UIImage(named: "delivery")
        if let delivery = delivery{
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(size: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
}

extension SearchForJobVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D? = manager.location!.coordinate
        currentLocation = locValue
        if let loc = locValue{
            service.updateJobAccepterLocation(location: loc)
            manager.stopUpdatingLocation()
        }
        setMapCamera()
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
