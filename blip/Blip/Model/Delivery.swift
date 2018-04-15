//
//  Delivery.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/8/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Firebase

class Delivery{
    
    var deliveryAddress: String!
    var deliveryPlacemark: CLPlacemark!
    var deliveryLocation: CLLocationCoordinate2D!
    var identifier: String!
    var origin: CLLocationCoordinate2D!
    var recieverName: String!
    var receiverPhoneNumber: String!
    
    init(deliveryLocation: CLLocationCoordinate2D, identifier: String, origin: CLLocationCoordinate2D, recieverName: String, recieverNumber: String) {
        self.deliveryLocation = deliveryLocation
        self.identifier = identifier
        self.origin = origin
        self.recieverName = recieverName
        self.receiverPhoneNumber = recieverNumber
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: (deliveryLocation.latitude), longitude: (deliveryLocation.longitude)), completionHandler: { (placemarks, error) in
            if(error == nil){
                let placeMark = placemarks?[0]
                self.deliveryPlacemark = placeMark
                self.deliveryAddress = self.parseAddress(placemark: self.deliveryPlacemark!)
                print("Address: ", self.deliveryAddress)
            }
        })
    }
    
    init?(snapshot: DataSnapshot) {
        guard !snapshot.key.isEmpty else {
            return nil
        }
        self.identifier = snapshot.key
        let deliveryValues = snapshot.value as? [String: AnyObject]
        self.deliveryLocation = CLLocationCoordinate2D(latitude: (deliveryValues!["deliveryLat"] as? Double)!, longitude: (deliveryValues!["deliveryLong"] as? Double)!)
        self.identifier = snapshot.key
        self.origin = CLLocationCoordinate2D(latitude: (deliveryValues!["originLat"] as? Double)!, longitude: (deliveryValues!["originLong"] as? Double)!)
        self.recieverName = deliveryValues!["recieverName"] as! String
        self.receiverPhoneNumber = deliveryValues!["recieverNumber"] as! String
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: (deliveryLocation.latitude), longitude: (deliveryLocation.longitude)), completionHandler: { (placemarks, error) in
            if(error == nil){
                let placeMark = placemarks?[0]
                self.deliveryPlacemark = placeMark
                self.deliveryAddress = self.parseAddress(placemark: self.deliveryPlacemark!)
            }
            else{
                print("An error occured: ",error!)
            }
        })
    }
    
    func parseAddress(placemark: CLPlacemark)->String{
        // put a space between "4" and "Melrose Place"
        let firstSpace = (placemark.subThoroughfare != nil && placemark.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (placemark.subThoroughfare != nil || placemark.thoroughfare != nil) && (placemark.subAdministrativeArea != nil || placemark.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (placemark.subAdministrativeArea != nil && placemark.administrativeArea != nil) ? " " : ""
        let thirdspace = (placemark.postalCode != nil) ? " " : ""
        
        let addressLine = String(
            format:"%@%@%@%@%@%@%@%@%@",
            // street number
            placemark.subThoroughfare ?? "",
            firstSpace,
            // street name
            placemark.thoroughfare ?? "",
            comma,
            // city
            placemark.locality ?? "",
            secondSpace,
            // state
            placemark.administrativeArea ?? "",
            thirdspace,
            //postalcode
            placemark.postalCode ?? ""
        )
        return addressLine
    }
}
