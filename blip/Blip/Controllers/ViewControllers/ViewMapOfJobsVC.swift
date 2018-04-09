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
    
//    func calculateRoute(waypoints: [Waypoint],
//                        completion: @escaping (Route?, Error?) -> ()) {
//
//        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
//        let startPoint = Waypoint(coordinate: currentLocation, coordinateAccuracy: -1, name: "Origin")
//        var waypointsWithCurrentLoc = waypoints
//        waypointsWithCurrentLoc.insert(startPoint, at: 0)
//        // Specify that the route is intended for automobiles avoiding traffic
//        let options = NavigationRouteOptions(waypoints: waypointsWithCurrentLoc, profileIdentifier: .automobileAvoidingTraffic)
//
//        // Generate the route object and draw it on the map
//        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
//            self.directionsRoute = routes?.first
//            // Draw the route on the map after creating it
//            self.drawRoute(route: self.directionsRoute!)
//        }
//    }
    
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
        return 6.0
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // Give our polyline a unique color by checking for its `title` property
        if (annotation.title == "Crema to Council Crest" && annotation is MGLPolyline) {
            // Mapbox cyan
            return UIColor(red: 59/255, green:178/255, blue:208/255, alpha:1)
        }
        else
        {
            return UIColor.green
        }
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 1
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

        if let castedAnnotation = annotation as? BlipAnnotation{
            
            var waypointList = [Waypoint]()
            MyAPIClient.sharedClient.optimizeRoute(locations: (castedAnnotation.job?.locList)!, completion: { (data) in
//                var ind = 0
//                while ind < (castedAnnotation.job?.locList.count)!{
//
//                    for way in arrayOfWaypoints{
//
//                        if (way["waypoint_index"] as! Int) == ind{
//                            print("found index:", ind)
//                            let name = (way["name"] as! String)
//                            let longitude = (way["location"] as! [Double])[0]
//                            let latitude = (way["location"] as! [Double])[1]
//                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                            let waypoint = Waypoint(coordinate: coordinate, coordinateAccuracy: -1, name: name)
//                            waypointList.append(waypoint)
//                            ind += 1
//                        }
//                    }
//                }
                
                print(data, "This is the waypoint list")
                mapView.removeAnnotations(mapView.annotations!)
                mapView.addAnnotation(annotation)
                let pickupAnnotation = BlipAnnotation(coordinate: (castedAnnotation.job?.pickupLocationCoordinates)!, title: "Pickup Point", subtitle: nil)
                mapView.addAnnotation(pickupAnnotation)
                mapView.showAnnotations([annotation, pickupAnnotation, self.map.userLocation!], animated: true)
                // if let here 
                self.drawRoute(data: data!)
            })
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
