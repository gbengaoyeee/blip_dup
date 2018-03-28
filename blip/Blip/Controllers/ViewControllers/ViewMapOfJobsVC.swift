//
//  ViewMapOfJobsVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-03-28.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Firebase
import Lottie
import CoreLocation
import Material
import FBSDKLoginKit
import Mapbox
import PopupDialog
import Alamofire
import Stripe
import Kingfisher
import NotificationBannerSwift
import AZDialogView

class ViewMapOfJobsVC: UIViewController {

    @IBOutlet weak var map: MGLMapView!
    
    var dbRef: DatabaseReference!
    var acceptedJob: Job!
    let service = ServiceCalls()
    var locationManager = CLLocationManager()
    let camera = MGLMapCamera()
    var currentLocation: CLLocationCoordinate2D!
    var paymentContext: STPPaymentContext? = nil
    let backendBaseURL: String? = "https://us-central1-blip-c1e83.cloudfunctions.net/"
    let stripePublishableKey = "pk_test_K45gbx2IXkVSg4pfmoq9SIa9"
    let companyName = "Blip"
    var locationTimer = Timer()
    var latestAccepted:Job!
    var allAnnotations: [String:CustomMGLAnnotation]!
    let check = LOTAnimationView(name: "check")
    var connectivity = Connectivity()
    var internet:Bool!
    let userDefault = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMap()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewMapOfJobsVC: MGLMapViewDelegate{
    
    func prepareMap(){
        
        self.map.delegate = self
        service.getJobsFromFirebase(MapView: self.map) { (annotations) in
            print("Got jobs from firebase")
            self.allAnnotations = annotations
        }
    }
}

extension ViewMapOfJobsVC: STPPaymentContextDelegate{
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        
        let source = paymentResult.source.stripeID
        MyAPIClient.sharedClient.addPaymentSource(id: source, completion: { (error) in })
        
    }
    
    
}

extension ViewMapOfJobsVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.camera.centerCoordinate = locValue
        self.camera.altitude = CLLocationDistance(11000)
        self.camera.pitch = CGFloat(60)
        self.map.setCenter(locValue, zoomLevel: 5, direction: 0, animated: false)
        self.map.setZoomLevel(7, animated: true)
        self.map.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        currentLocation = locValue
        service.updateJobAccepterLocation(location: locValue)
        manager.stopUpdatingLocation()
    }
}
