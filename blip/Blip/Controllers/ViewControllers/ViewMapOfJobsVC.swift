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
import SwiftIcons

class ViewMapOfJobsVC: UIViewController {

    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var postTestJobButton: RaisedButton!
    
    var dbRef: DatabaseReference!
    var acceptedJob: Job!
    let service = ServiceCalls.instance
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
        useCurrentLocations()
        prepareMap()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func testPost(_ sender: Any) {
        service.getCurrentUserInfo { (user) in
            
            self.service.addTestJob(title: "Pickup", orderer: user,  deliveryLocation: self.currentLocation, pickupLocation: CLLocationCoordinate2D(latitude: -79.68, longitude: 43.61), earnings: 5.00, estimatedTime: 10.00)
        }
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
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {

        guard annotation is MGLPointAnnotation else {
            return nil
        }
        let annotationView = CustomAnnotationView()
        annotationView.frame = CGRect(x: 0, y: 0, width: 50, height: 50 )
        annotationView.backgroundColor = UIColor.white
        annotationView.layer.cornerRadius = annotationView.frame.size.height/2
        annotationView.clipsToBounds = true
        let deliveryIcon = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(width: 50, height: 50))
        let deliveryImageView = UIImageView(image: deliveryIcon)
        deliveryImageView.isUserInteractionEnabled = true
        annotationView.addSubview(deliveryImageView)
        annotationView.layer.cornerRadius = annotationView.frame.size.height/2
        annotationView.isUserInteractionEnabled = true
        return annotationView
        
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

        print(map.annotations)
        if let castedAnnotation = annotation as? CustomMGLAnnotation{
            
            let allAnnotations = map.annotations!
            map.removeAnnotations(allAnnotations)
            let pickupAnnotation = MGLPointAnnotation()
            pickupAnnotation.coordinate = (castedAnnotation.job?.pickupLocationCoordinates)!
            self.map.addAnnotation(annotation)
            self.map.addAnnotation(pickupAnnotation)
        }
    }
    
    func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
        
        self.map.removeAnnotations(self.map.annotations!)
        for annotation in allAnnotations.values{
            self.map.addAnnotation(annotation)
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
