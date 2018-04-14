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
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation
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
    
    var directionsRoute: Route?
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
    var allAnnotations: [String:BlipAnnotation]!
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
    
    override func viewDidAppear(_ animated: Bool) {
        let screenBrightness = UIScreen.main.brightness
        
        if screenBrightness < 0.4{
            map.styleURL = URL(string: "mapbox://styles/srikanthsrnvs/cjft4wgos7sa72rn0f7ykelkm")
            UIApplication.shared.statusBarStyle = .lightContent
        }
        else{
            map.styleURL = URL(string: "mapbox://styles/srikanthsrnvs/cjd6ciwwm54my2rms3052j5us")
            UIApplication.shared.statusBarStyle = .default
        }
    }

    @IBAction func testPost(_ sender: Any) {
        service.getCurrentUserInfo { (user) in
            
            let delivery1 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d1", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            let delivery2 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d2", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            let delivery3 = Delivery(deliveryLocation: self.generateRandomCoordinates(currentLoc: self.currentLocation, min: 1000, max: 2000), identifier: "d3", origin: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68))
            self.service.addTestJob(title: "Pickup", orderer: user,  deliveries: [delivery1, delivery2, delivery3], pickupLocation: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68), earnings: 5.00, estimatedTime: 10.00)
        }
    }
}

extension ViewMapOfJobsVC: MGLMapViewDelegate{
    
    func prepareMap(){
        self.map.delegate = self
        map.showsUserLocation = true
        map.showsUserHeadingIndicator = true
        map.userTrackingMode = .followWithHeading
        service.getJobsFromFirebase(MapView: self.map) { (annotations) in
            print("Got jobs from firebase")
            self.allAnnotations = annotations
        }
    }
    
    func drawRoute(data: Data) {
        do {
            // Convert the file contents to a shape collection feature object
            let shapeCollectionFeature = try MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
            
            let polyline = shapeCollectionFeature
                // Optionally set the title of the polyline, which can be used for:
                //  - Callout view
                //  - Object identification
            polyline.title = polyline.attributes["name"] as? String
                // Add the annotation on the main thread
            DispatchQueue.main.async(execute: {
                    // Unowned reference to self to prevent retain cycle
                [unowned self] in
                self.map.addAnnotation(polyline)
            })
        }
        catch {
            print("GeoJSON parsing failed")
        }
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 4.5
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return #colorLiteral(red: 0.2796384096, green: 0.4718205929, blue: 1, alpha: 1)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // Substitute our custom view for the user location annotation. This custom view is defined below.
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView()
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        if let annotationTitle = annotation.title{
            if let unwrappedTitle = annotationTitle{
                if unwrappedTitle == "Pickup"{
                    
                    let annotationImage = UIImage(icon: .googleMaterialDesign(.star), size: CGSize(size: 50), textColor: UIColor.yellow, backgroundColor: UIColor.clear)
                    let mglAnnotationImage = MGLAnnotationImage(image: annotationImage, reuseIdentifier: "Pickup")
                    return mglAnnotationImage
                }
                    
                else if unwrappedTitle == "Delivery"{
                    
                    let annotationImage = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(size: 40), textColor: UIColor.white, backgroundColor: UIColor.clear)
                    let mglAnnotationImage = MGLAnnotationImage(image: annotationImage, reuseIdentifier: "Delivery")
                    return mglAnnotationImage
                }
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 1
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

//        if let annotationTitle = annotation.title{
//            if let unwrappedTitle = annotationTitle{
//                if unwrappedTitle == "Pickup"{
//                    print("Tapped pickup")
//                    if let castedAnnotation = annotation as? BlipAnnotation{
//                        
//                        var locationList = (castedAnnotation.job?.locList)!
//                        locationList.append((mapView.userLocation?.coordinate)!)
//                        
//                        MyAPIClient.sharedClient.optimizeRoute(locations: locationList, completion: { (data),<#arg#>,<#arg#>  in
//                            
//                            mapView.removeAnnotations(mapView.annotations!)
//                            mapView.addAnnotation(annotation)
//                            
//                            var allAnnotations = mapView.annotations
//                            allAnnotations?.append(self.map.userLocation!)
//                            
//                            for delivery in (castedAnnotation.job?.deliveries)!{
//                                
//                                let deliveryAnnotation = MGLPointAnnotation()
//                                deliveryAnnotation.title = "Delivery"
//                                deliveryAnnotation.coordinate = delivery.deliveryLocation
//                                deliveryAnnotation.subtitle = delivery.identifier
//                                allAnnotations?.append(deliveryAnnotation)
//                                mapView.addAnnotation(deliveryAnnotation)
//                            }
//                            mapView.showAnnotations(allAnnotations!, animated: true)
//                            // if let here
//                            self.drawRoute(data: data!)
//                        })
//                    }
//                }
//            }
//        }
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
