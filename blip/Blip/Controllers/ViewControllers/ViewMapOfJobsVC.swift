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
            
            self.service.addTestJob(title: "Pickup", orderer: user,  deliveryLocation: self.currentLocation, pickupLocation: CLLocationCoordinate2D(latitude: 43.61, longitude: -79.68), earnings: 5.00, estimatedTime: 10.00)
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
    
    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (Route?, Error?) -> ()) {
        
        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        
        // Specify that the route is intended for automobiles avoiding traffic
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // Draw the route on the map after creating it
            self.drawRoute(route: self.directionsRoute!)
        }
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route’s coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = map.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and width
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 0.2796384096, green: 0.4718205929, blue: 1, alpha: 1))
            lineStyle.lineWidth = MGLStyleValue(rawValue: 8)
            
            // Add the source and style layer of the route line to the map
            map.style?.addSource(source)
            map.style?.addLayer(lineStyle)
        }
    }

//
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        guard annotation is MGLPointAnnotation else {
//            return nil
//        }
//        let annotationView = CustomAnnotationView()
//        annotationView.frame = CGRect(x: 0, y: 0, width: 50, height: 50 )
//        annotationView.backgroundColor = UIColor.white
//        annotationView.layer.cornerRadius = annotationView.frame.size.height/2
//        annotationView.clipsToBounds = true
//        let deliveryIcon = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(width: 50, height: 50))
//        let deliveryImageView = UIImageView(image: deliveryIcon)
//        deliveryImageView.isUserInteractionEnabled = true
//        annotationView.addSubview(deliveryImageView)
////        annotationView.layer.cornerRadius = annotationView.frame.size.height/2
//        annotationView.isUserInteractionEnabled = true
//        return annotationView
//    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? BlipAnnotation,
            
            let image = point.image,
            let reuseIdentifier = point.reuseIdentifier {
            
            if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
                // The annotatation image has already been cached, just reuse it.
                return annotationImage
            } else {
                // Create a new annotation image.
                return MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
            }
        }
        
        // Fallback to the default marker image.
        return MGLAnnotationImage(image: UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(width: 50, height: 50)), reuseIdentifier: "pickupAnnotation")
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

        if let castedAnnotation = annotation as? BlipAnnotation{
            map.removeAnnotations(map.annotations!)
            map.addAnnotation(annotation)
            let pickupAnnotation = MGLPointAnnotation()
            pickupAnnotation.coordinate = (castedAnnotation.job?.pickupLocationCoordinates)!
            self.map.addAnnotation(pickupAnnotation)
            map.showsUserLocation = true
            map.showAnnotations(map.annotations!, animated: true)
            calculateRoute(from: (map.userLocation?.coordinate)!, to: pickupAnnotation.coordinate, completion: { (route, error) in
                if error != nil{
                    print("Error calculating route to pickup point")
                }
            })
            calculateRoute(from: (pickupAnnotation.coordinate), to: annotation.coordinate) { (route, error) in
                if error != nil {
                    print("Error calculating route to delivery point")
                }
            }
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
