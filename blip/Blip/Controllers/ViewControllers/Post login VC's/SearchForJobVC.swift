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
import Kingfisher
import PopupDialog
import Firebase

class SearchForJobVC: UIViewController {

    @IBOutlet weak var earningsLabel: RaisedButton!
    @IBOutlet weak var goButtonPulseAnimation: UIView!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet var map: MGLMapView!
    @IBOutlet weak var earningsLoader: UIView!
    
    let pulsator = Pulsator()
    var gradient: CAGradientLayer!
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var service = ServiceCalls.instance
    let userDefaults = UserDefaults.standard
    var foundJob: Job!
    var unfinishedJob: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        goButton.isUserInteractionEnabled = false
        prepareLocationServices()
        NotificationCenter.default.addObserver(self, selector:#selector(prepareLocationServices), name:
            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareMap()
        getBalance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCurrentDevice()
        checkForUnfinishedJobs()
    }
    
    override func viewWillLayoutSubviews() {
        prepareGoButton()
        prepareBalanceLabel()
        prepareBlur()
    }
    
    func prepareBlur(){
        gradient = CAGradientLayer()
        gradient.frame = map.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0.07, 0.9, 1]
        map.layer.mask = gradient
    }
    
    @objc func prepareLocationServices(){
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus(){
            case .notDetermined:
                self.locationManager.requestAlwaysAuthorization()
                self.locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                let locationError = PopupDialog(title: "Location permission denied", message: "blip needs permission to access your location information, or we cannot match you with jobs around your area. Please go to settings; Privacy; Location services; and turn on location services for blip", gestureDismissal: false)
                present(locationError, animated: true, completion: nil)
            case .authorizedAlways, .authorizedWhenInUse:
                self.presentedViewController?.dismiss(animated: true, completion: nil)
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                locationManager.startUpdatingLocation()
            }
        }
        else{
            let errorPopup = PopupDialog(title: "Error", message: "We cannot determine your location. Please go to settings, and re-enable location services", gestureDismissal: false)
            present(errorPopup, animated: true, completion: nil)
        }
    }
    
    func prepareBalanceLabel(){
        earningsLoader.borderColor = UIColor.clear
        earningsLoader.layer.borderWidth = 2.5
        earningsLoader.layer.cornerRadius = earningsLoader.frame.size.height/2
        earningsLoader.backgroundColor = UIColor.clear
        earningsLabel.borderColor = UIColor.white
        earningsLabel.layer.borderWidth = 2.5
        earningsLabel.layer.cornerRadius = earningsLabel.frame.size.height/2
        earningsLabel.ApplyOuterShadowToButton()
        earningsLoader.ApplyOuterShadowToView()
    }
    
    func getBalance(){
        earningsLabel.isHidden = true
        let loader = LOTAnimationView(name: "earningsLoaderBlue")
        earningsLoader.handledAnimation(Animation: loader, width: 1, height: 1)
        loader.play()
        loader.loopAnimation = true
        MyAPIClient.sharedClient.getAccountBalance(emailHash: self.service.emailHash) { (balance) in
            if let balance = balance{
                let accountBalance = Double(balance)!/100
                let text = String(format: "%.2f", arguments: [accountBalance])
                self.earningsLabel.title = "$ \(text)"
                loader.stop()
                loader.removeFromSuperview()
                self.earningsLabel.isHidden = false
            }
        }
    }
    
    func checkLocationServices() -> Bool{
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                let locationError = PopupDialog(title: "Location permission denied", message: "Blip needs permission to access your location information, or we cannot match you with jobs around your area. Please go to settings -> Privacy -> Location services; and turn on location services for blip")
                self.present(locationError, animated: true, completion: nil)
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                return true
            }
        }
        return false
    }
    
    func showUnfinishedBanner(){
        let banner = NotificationBanner(title: "Unfinished delivery", subtitle: "Tap go to complete your unfinished delivery",style: .info)
        banner.autoDismiss = true
        banner.dismissOnTap = true
        banner.dismissOnSwipeUp = true
        banner.show()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let annotations = map.annotations{
            map.removeAnnotations(annotations)
        }
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
            dest.unfinishedJob = self.unfinishedJob
        }
    }
    
    func prepareGoButton(){
        pulsator.backgroundColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
        goButton.makeCircular()
        goButton.borderColor = UIColor.white
        goButton.layer.borderWidth = 2.5
        goButton.ApplyOuterShadowToButton()
    }
    
    func startButtonPulse(){
        pulsator.numPulse = 2
        pulsator.animationDuration = 3.0
        pulsator.radius = 150
        pulsator.repeatCount = .infinity
        pulsator.start()
        goButtonPulseAnimation.layer.addSublayer(pulsator)
    }
    
    func checkForUnfinishedJobs(){

        service.checkIncompleteJobs { (exist) in
            self.goButton.isUserInteractionEnabled = true
            if exist{
                self.showUnfinishedBanner()
            }
            else{
                self.startButtonPulse()
            }
        }
    }
    
    @IBAction func searchForJob(_ sender: Any) {
        
        goButton.isUserInteractionEnabled = false
        if !checkLocationServices(){
            return
        }
        self.service.getUnfinishedJobs(myLocation: self.currentLocation) { (job) in
            if let job = job{
                self.unfinishedJob = true
                self.foundJob = job
                self.performSegue(withIdentifier: "foundJob", sender: self)
                self.goButton.isUserInteractionEnabled = true
                return
            }
            else{
                self.unfinishedJob = false
                let leftImageView = UIView()
                let loading = LOTAnimationView(name: "loading")
                loading.loopAnimation = true
                leftImageView.handledAnimation(Animation: loading, width: 1, height: 1)
                let banner = NotificationBanner(title: "Please wait", subtitle: "Looking for job", leftView: leftImageView, rightView: nil, style: .info)
                banner.dismissOnSwipeUp = false
                banner.show()
                loading.play()
                
                self.service.findJob(myLocation: self.currentLocation, userHash: self.service.emailHash) { (errorCode, job) in
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        banner.dismiss()
                        loading.stop()
                        if errorCode != nil{
                            if errorCode == 400{
                                //Not verified
                                let newBanner = NotificationBanner(title: "Error", subtitle: "Account not verified", style: .warning)
                                newBanner.autoDismiss = true
                                newBanner.show()
                                newBanner.dismissOnSwipeUp = true
                                newBanner.dismissOnTap = true
                                print("Not verified")
                                self.goButton.isUserInteractionEnabled = true
                                return
                            }
                            else if errorCode == 500{
                                //Flagged
                                print("Here")
                                let newBanner = NotificationBanner(title: "Error", subtitle: "Your account has been disabled due to leaving a job. Please contact us to unlock your account", style: .warning)
                                newBanner.autoDismiss = false
                                newBanner.show()
                                newBanner.dismissOnSwipeUp = true
                                newBanner.dismissOnTap = true
                                print("Flagged")
                                self.goButton.isUserInteractionEnabled = true
                                return
                            }else{
                                // No job Found
                                let newBanner = NotificationBanner(title: "Error", subtitle: "No job found at this time", style: .info)
                                newBanner.autoDismiss = true
                                newBanner.show()
                                newBanner.dismissOnSwipeUp = true
                                newBanner.dismissOnTap = true
                                print("No job Found")
                                self.goButton.isUserInteractionEnabled = true
                                return
                            }
                        }
                        guard let job = job else{
                            print("Something wrong with getting job")
                            return
                        }
                        self.foundJob = job
                        self.performSegue(withIdentifier: "foundJob", sender: self)
                        self.goButton.isUserInteractionEnabled = true
                    })
                }
            }
        }
    }
}

extension SearchForJobVC: MGLMapViewDelegate{
    
    func prepareMap(){
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
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(width: 40, height: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
}

extension SearchForJobVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D? = manager.location!.coordinate
        currentLocation = locValue
        service.updateJobAccepterLocation(location: locValue!)
        manager.stopUpdatingLocation()
        setMapCamera()
        
    }
}

