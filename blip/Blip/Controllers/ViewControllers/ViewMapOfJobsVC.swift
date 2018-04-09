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
    
    func calculateRoute(waypoints: [Waypoint],
                        completion: @escaping (Route?, Error?) -> ()) {
        
        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let startPoint = Waypoint(coordinate: currentLocation, coordinateAccuracy: -1, name: "Origin")
        var waypointsWithCurrentLoc = waypoints
        waypointsWithCurrentLoc.insert(startPoint, at: 0)

        let options = NavigationRouteOptions(waypoints: waypointsWithCurrentLoc, profileIdentifier: .automobile)
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            if error != nil{
                print("Error occured:", error)
            }
            else{
                self.directionsRoute = routes?.first
                // Draw the route on the map after creating it
                self.drawRoute(route: self.directionsRoute!)
            }
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
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // Substitute our custom view for the user location annotation. This custom view is defined below.
        if annotation is MGLUserLocation && mapView.userLocation != nil {
            return CustomUserLocationAnnotationView()
        }
        return nil
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        if let annotationTitle = annotation.title{
            print(annotationTitle!, "This is the annotation title")
            if annotationTitle == nil{
                return nil
            }
                
            else if annotationTitle! == "Pickup"{
                
                let annotationImage = UIImage(icon: .icofont(.foodBasket), size: CGSize(size: 50), textColor: UIColor.black, backgroundColor: UIColor.white)
                let mglAnnotationImage = MGLAnnotationImage(image: annotationImage, reuseIdentifier: "Pickup")
                return mglAnnotationImage
            }
                
            else if annotationTitle! == "Delivery"{
                
                let annotationImage = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(size: 50), textColor: UIColor.black, backgroundColor: UIColor.white)
                let mglAnnotationImage = MGLAnnotationImage(image: annotationImage, reuseIdentifier: "Delivery")
                return mglAnnotationImage
            }
        }
        
        return nil
    }
    
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

        if let castedAnnotation = annotation as? BlipAnnotation{
            
            var waypointList = [Waypoint]()
            MyAPIClient.sharedClient.optimizeRoute(locations: (castedAnnotation.job?.locList)!, completion: { (data) in
                let arrayOfWaypoints = data!["waypoints"] as! [[String:Any]]
                
                var ind = 0
                while ind < (castedAnnotation.job?.locList.count)!{
                    
                    for way in arrayOfWaypoints{
                        
                        if (way["waypoint_index"] as! Int) == ind{
                            print("found index:", ind)
                            let name = (way["name"] as! String)
                            let longitude = (way["location"] as! [Double])[0]
                            let latitude = (way["location"] as! [Double])[1]
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let waypoint = Waypoint(coordinate: coordinate, coordinateAccuracy: -1, name: name)
                            waypointList.append(waypoint)
                            ind += 1
                        }
                    }
                }
                
                print(waypointList, "This is the waypoint list")
                mapView.removeAnnotations(mapView.annotations!)
                mapView.addAnnotation(annotation)
                
                for delivery in (castedAnnotation.job?.deliveries)!{
                    
                    let deliveryAnnotation = BlipAnnotation(coordinate: delivery.deliveryLocation, title: "Delivery", subtitle: delivery.deliveryAddress)
                    mapView.addAnnotation(deliveryAnnotation)
                }
                var allAnnotations = mapView.annotations
                allAnnotations?.append(mapView.userLocation!)
                mapView.showAnnotations(allAnnotations!, animated: true)
                self.calculateRoute(waypoints: waypointList, completion: { (route, error) in
                    if error != nil{
                        print("Error calculating route to pickup point")
                    }
                })
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
