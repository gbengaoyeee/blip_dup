//
//  TestMGLNav.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-02-01.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox
import MapboxNavigation
import MapboxDirections
import MapboxCoreNavigation

class TestMGLNav: UIViewController, MGLMapViewDelegate {

    var map: NavigationMapView!
    var directionsRoute: Route?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map = NavigationMapView(frame: view.bounds)
        view.addSubview(map)
        
        map.delegate = self
        
        map.showsUserLocation = true
        map.setUserTrackingMode(.follow, animated: true)

        let setDestination = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressed(_:)))
        map.addGestureRecognizer(setDestination)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        let navigationController = TestNavigationViewController(for: self.directionsRoute!)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    
    
    @objc func didLongPressed(_ sender: UILongPressGestureRecognizer){
        guard sender.state == .began else{return}
        
        let point = sender.location(in: self.map)
        let coordinate = self.map.convert(point, toCoordinateFrom: self.map)
        
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Start Navi?"
        map.addAnnotation(annotation)
        
        calculateRoute(from: (map.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
            if error != nil{
                print(error.localizedDescription)
            }
        }
    }
    
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (Route?, Error)->()){
        
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "finish")
        
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        _ = Directions.shared.calculate(options, completionHandler: { (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            self.drawRoute(route: self.directionsRoute!)
        })
    }
    
    func drawRoute(route: Route){
        guard route.coordinateCount > 0 else{return}
        
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        if let source = map.style?.source(withIdentifier: "route-source") as? MGLShapeSource{
            source.shape = polyline
        }else{
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            let lineStyle = MGLLineStyleLayer(identifier: "route-source", source: source)
            lineStyle.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))
            lineStyle.lineWidth = MGLStyleValue(rawValue: 3)
            
            map.style?.addSource(source)
            map.style?.addLayer(lineStyle)
        }
    }

}
