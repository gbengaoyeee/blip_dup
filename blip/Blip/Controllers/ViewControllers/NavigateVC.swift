//
//  DropoffVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/18/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import MapKit
import Mapbox
import Material
import Pulsator
import MapboxDirections
import Kingfisher
import MapboxCoreNavigation

class NavigateVC: UIViewController {

    @IBOutlet weak var instructionCard: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var subInstructionLabel: UILabel!
    @IBOutlet weak var mainInstructionLabel: UILabel!
    @IBOutlet weak var cancelButton: RaisedButton!
    @IBOutlet weak var navigateButton: RaisedButton!
    @IBOutlet weak var callButton: RaisedButton!
    @IBOutlet weak var pulseLayer: UIView!
    
    let service = ServiceCalls.instance
    var job: Job!
    var waypoints = [Waypoint]()
    var directionsRoute: Route?
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var gradient: CAGradientLayer!
    var fromIndex: Int = 0
    var toIndex: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMap()
        prepareButtons()
        useCurrentLocations()
        preparePulse()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareButtons(){
        cancelButton.makeCircular()
        navigateButton.makeCircular()
        callButton.makeCircular()
        cancelButton.setIcon(icon: .googleMaterialDesign(.cancel), iconSize: 30, color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        navigateButton.setIcon(icon: .googleMaterialDesign(.navigation), iconSize: 30, color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        callButton.setIcon(icon: .googleMaterialDesign(.call), iconSize: 30, color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        cancelButton.borderColor = UIColor.white
        cancelButton.layer.borderWidth = 2.5
        callButton.borderColor = UIColor.white
        callButton.layer.borderWidth = 2.5
        navigateButton.borderColor = UIColor.white
        navigateButton.layer.borderWidth = 2.5
        instructionCard.ApplyOuterShadowToView()
        instructionCard.ApplyCornerRadiusToView()
    }
    
    func setMapCamera(){
        let camera = MGLMapCamera(lookingAtCenter: map.centerCoordinate, fromDistance: 4500, pitch: 15, heading: 0)
        
        // Animate the camera movement over 5 seconds.
        map.setCamera(camera, withDuration: 2, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        prepareMapForRoute(from: waypoints[fromIndex].coordinate, to: waypoints[toIndex].coordinate)
    }
    
    func preparePulse(){
        let pulsator = Pulsator()
        pulsator.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        pulsator.numPulse = 2
        pulsator.animationDuration = 1.0
        pulsator.radius = 20
        pulsator.repeatCount = .infinity
        pulsator.start()
        pulseLayer.layer.addSublayer(pulsator)
    }
    
    func prepareMap(){
        map.showsUserLocation = true
        map.delegate = self
        map.userTrackingMode = .followWithHeading
        map.showsUserHeadingIndicator = true
    }
    
    func prepareMapForRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D){
        
        let destinationAnnotation = MGLPointAnnotation()
        destinationAnnotation.coordinate = to
        map.addAnnotation(destinationAnnotation)
        
        calculateRoute(from: from, to: to) { (route, error) in
            if error != nil{
                print(error!)
            }
        }
        fromIndex += 1
        toIndex += 1
        
        if let user = map.userLocation{
            let padding = UIEdgeInsetsMake(100, 10, self.view.frame.size.height*0.8, 10)
            map.showAnnotations([user, destinationAnnotation], edgePadding: padding, animated: true)
        }
    }
}

extension NavigateVC: MGLMapViewDelegate{
    
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
            lineStyle.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = MGLStyleValue(rawValue: 3)
            
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
        else{
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            imageView.image = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(size: 35), textColor: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1))
            let view = MGLAnnotationView()
            view.addSubview(imageView)
            return view
        }
        return nil
    }
    
}

extension NavigateVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        map.setCenter(locValue, zoomLevel: 7, direction: 0, animated: false)
        currentLocation = locValue
        service.updateJobAccepterLocation(location: locValue)
        setMapCamera()
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

extension NavigateVC{
    
    
}
