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
import Floaty
import Pulsator
import NotificationBannerSwift
import Lottie
import Kingfisher
//REMOVE ALL BELOW
import PopupDialog
import Firebase

class SearchForJobVC: UIViewController {

    @IBOutlet weak var earningsLabel: RaisedButton!
    @IBOutlet weak var goButtonPulseAnimation: UIView!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet var map: MGLMapView!
    @IBOutlet weak var testJobPost: UIButton!
    @IBOutlet weak var menu: Floaty!
    @IBOutlet weak var earningsLoader: UIView!
    
    @IBOutlet weak var menuTop: NSLayoutConstraint!
    
    let pulsator = Pulsator()
    var gradient: CAGradientLayer!
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var service = ServiceCalls.instance
    let userDefaults = UserDefaults.standard
    var foundJob: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        locationManager.delegate = self
        prepareBlur()
        prepareMenuButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
        prepareMap()
        prepareGoButton()
        getBalance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCurrentDevice()
    }
    
    func getBalance(){
        earningsLoader.borderColor = UIColor.clear
        earningsLoader.layer.borderWidth = 2.5
        earningsLoader.layer.cornerRadius = 15
        earningsLoader.backgroundColor = UIColor.clear
        let loader = LOTAnimationView(name: "earningsLoaderBlue")
        earningsLoader.handledAnimation(Animation: loader, width: 1, height: 1)
        loader.play()
        loader.loopAnimation = true
        earningsLabel.borderColor = UIColor.white
        earningsLabel.layer.borderWidth = 2.5
        earningsLabel.layer.cornerRadius = 15
        earningsLabel.isHidden = true
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
    
    func prepareMenuButton(){
//        menu.makeCircular()
//        menu.buttonColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
//        menu.buttonImage = UIImage(icon: .googleMaterialDesign(.add), size: CGSize(size: 30), textColor: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1))
        menu.addItem("Test", icon: UIImage(icon: .googleMaterialDesign(.verifiedUser), size: CGSize(size: 25), textColor: UIColor.white, backgroundColor: UIColor.blue)) { (item) in
            print("Hi")
        }
        menu.fabDelegate = self
        menu.addItem(title: "hello")
        menu.openAnimationType = .slideLeft
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
        let banner = NotificationBanner(title: "Unfinished delivery", subtitle: "Tap to continue your unfinished delivery",style: .info)
        banner.onTap = {
            self.performSegue(withIdentifier: "foundJob", sender: self)
            banner.dismiss()
        }
        banner.autoDismiss = false
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
        }
    }
    
    func prepareBlur(){
//        gradient = CAGradientLayer()
//        gradient.frame = map.bounds
//        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
//        gradient.locations = [0, 0.2, 0.8, 1]
//        map.layer.mask = gradient
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
        goButton.isUserInteractionEnabled = false
    }
    
    func checkForUnfinishedJobs(){
        service.checkIncompleteJobs(myLocation: self.currentLocation) { (exist, job) in
            if exist{
                self.foundJob = job
                self.showUnfinishedBanner()
            }
            else{
                self.goButton.isUserInteractionEnabled = true
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        gradient.frame = map.bounds
    }
    
    @IBAction func postTestJob(_ sender: Any) {
        service.getCurrentUserInfo { (user) in
            let deliveryLocation = self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 100, max: 400)
            let pickupLocation = self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 100, max: 500)
            MyAPIClient.sharedClient.makeDeliveryRequest(storeID: "-LDCTqOOk7e1GNlpQcGR", deliveryLat: deliveryLocation.latitude, deliveryLong: deliveryLocation.longitude, deliveryMainInstruction: "Deliver to Srikanth Srinivas", deliverySubInstruction: "Go to main entrace, and buzz code 2003", originLat: pickupLocation.latitude, originLong: pickupLocation.longitude, pickupMainInstruction: "Pickup from xyz", pickupSubInstruction: "Go to front entrance of xyz, order number 110021 is waiting for you", recieverName: "Srikanth Srinivas", recieverNumber: "6478229867", pickupNumber: "6479839837")
        }
    }
    
    @IBAction func searchForJob(_ sender: Any) {
        
        if !checkLocationServices(){
            return
        }

        goButton.isUserInteractionEnabled = false
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
                        return
                    }else{
                        // No job Found
                        let newBanner = NotificationBanner(title: "Error", subtitle: "No job found at this time", style: .info)
                        newBanner.autoDismiss = true
                        newBanner.show()
                        newBanner.dismissOnSwipeUp = true
                        newBanner.dismissOnTap = true
                        print("No job Found")
                        return
                    }
                }
                guard let job = job else{
                    print("Something wrong with getting job")
                    return
                }
                self.foundJob = job
                self.goButton.isUserInteractionEnabled = true
                self.performSegue(withIdentifier: "foundJob", sender: self)
            })
            self.goButton.isUserInteractionEnabled = true
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
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(size: 40)), reuseIdentifier: "delivery")
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
        checkForUnfinishedJobs()
        setMapCamera()
        
    }
}

extension SearchForJobVC: FloatyDelegate{
    
    func floatyWillOpen(_ floaty: Floaty) {
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveLinear, animations: {
            self.menuTop.constant += 100
        }, completion: nil)
    }
    
    func floatyWillClose(_ floaty: Floaty) {
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveLinear, animations: {
            self.menuTop.constant = 25
        }, completion: nil)
    }
    
    fileprivate func prepareAndReturnLogout() -> FloatyItem{
        
        let item = FloatyItem()
        item.buttonColor = UIColor.white
        item.icon = UIImage(icon: .icofont(.logout), size: CGSize(size: 25), textColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), backgroundColor: UIColor.white)
        item.title = "Logout"
        item.titleColor = UIColor.darkText
        item.handler = { item in
            do{
                try Auth.auth().signOut()
                print("Logged out")
            } catch let signOutError as NSError{
                let signOutErrorPopup = PopupDialog(title: "Error", message: "Error signing you out, try again later" + signOutError.localizedDescription )
                self.present(signOutErrorPopup, animated: true, completion: nil)
                print ("Error signing out: %@", signOutError)
            }
        }
        return item
    }
    
    fileprivate func prepareAndReturnSettings() -> FloatyItem{
        
        let item = FloatyItem()
        item.buttonColor = UIColor.white
        item.icon = UIImage(icon: .icofont(.verificationCheck), size: CGSize(size: 25), textColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), backgroundColor: UIColor.white)
        item.title = "Update Account"
        item.titleColor = UIColor.darkText
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let settingsPage = sb.instantiateViewController(withIdentifier: "settings") as! SettingsVC
        self.present(settingsPage, animated: true, completion: nil)
        item.handler = { item in
            self.present(settingsPage, animated: true, completion: nil)
        }
        return item
    }
}


