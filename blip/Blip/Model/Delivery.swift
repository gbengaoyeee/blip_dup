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
    var earnings: String!
    var origin: CLLocationCoordinate2D!
    var recieverName: String!
    var receiverPhoneNumber: String!
    var pickupMainInstruction: String!
    var pickupSubInstruction: String!
    var deliveryMainInstruction: String!
    var deliverySubInstruction: String!
    var store: Store!
    var pickupNumber: String!
    var state: String?
    
    init(deliveryLocation: CLLocationCoordinate2D, identifier: String, origin: CLLocationCoordinate2D, recieverName: String, recieverNumber: String, pickupNumber: String, pickupMainInstruction: String, pickupSubInstruction: String, deliveryMainInstruction: String, deliverySubInstruction: String, storeID:String, earnings: String) {
        self.deliveryLocation = deliveryLocation
        self.identifier = identifier
        self.origin = origin
        self.earnings = earnings
        self.recieverName = recieverName
        self.receiverPhoneNumber = recieverNumber
        self.pickupMainInstruction = pickupMainInstruction
        self.pickupSubInstruction = pickupSubInstruction
        self.deliveryMainInstruction = deliveryMainInstruction
        self.deliverySubInstruction = deliverySubInstruction
        self.pickupNumber = pickupNumber
        
        //setting the store
        let storeRef = Database.database().reference().child("stores").child(storeID)
        storeRef.observeSingleEvent(of: .value) { (snap) in
            if let storeVal = snap.value as? [String:Any]{
                let storeLogo = storeVal["storeLogo"] as! String
                let storeBackground = storeVal["storeBackground"] as! String
                let storeDescription = storeVal["description"] as! String
                let latitude = storeVal["locationLat"] as! Double
                let longitude = storeVal["locationLat"] as! Double
                let storeName = storeVal["storeName"] as! String
                self.store = Store(storeID: storeID, name: storeName, storeLogo: URL(string: storeLogo)!, storeBackground: URL(string: storeBackground)!, description: storeDescription, latitude: latitude, longitude: longitude)
            }
        }
        
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: (deliveryLocation.latitude), longitude: (deliveryLocation.longitude)), completionHandler: { (placemarks, error) in
            if(error == nil){
                let placeMark = placemarks?[0]
                self.deliveryPlacemark = placeMark
                self.deliveryAddress = self.parseAddress(placemark: self.deliveryPlacemark!)
            }
        })
    }
    
    init?(snapshot: DataSnapshot) {
        guard !snapshot.key.isEmpty else {
            return nil
        }
        self.identifier = snapshot.key
        let deliveryValues = snapshot.value as? [String: AnyObject]
        let deliveryLat = Double(deliveryValues!["deliveryLat"] as! String)!
        let deliveryLong = Double(deliveryValues!["deliveryLong"] as! String)!
        let originLat = Double(deliveryValues!["originLat"] as! String)!
        let originLong = Double(deliveryValues!["originLong"] as! String)!
        self.deliveryLocation = CLLocationCoordinate2D(latitude: deliveryLat, longitude: deliveryLong)
        self.earnings = String(deliveryValues!["chargeAmount"] as! Int)
        self.identifier = snapshot.key
        if let state = deliveryValues!["state"] as? String{
            self.state = state
        }
        self.origin = CLLocationCoordinate2D(latitude: originLat, longitude: originLong)
        self.recieverName = deliveryValues!["recieverName"] as! String
        self.receiverPhoneNumber = deliveryValues!["recieverNumber"] as! String
        self.pickupMainInstruction = deliveryValues!["pickupMainInstruction"] as! String
        self.pickupSubInstruction = deliveryValues!["pickupSubInstruction"] as! String
        self.deliveryMainInstruction = deliveryValues!["deliveryMainInstruction"] as! String
        self.deliverySubInstruction = deliveryValues!["deliverySubInstruction"] as! String
        self.pickupNumber = deliveryValues!["pickupNumber"] as! String
        
        //setting the store
        let storeID = deliveryValues!["storeID"] as! String
        let storeRef = Database.database().reference().child("stores").child(storeID)
        storeRef.observeSingleEvent(of: .value) { (snap) in
            if let storeVal = snap.value as? [String:Any]{
                let storeLogo = storeVal["storeLogo"] as! String
                let storeBackground = storeVal["storeBackground"] as! String
                let storeDescription = storeVal["description"] as! String
                let latitude = Double(storeVal["locationLat"] as! String)!
                let longitude = Double(storeVal["locationLat"] as! String)!
                let storeName = storeVal["storeName"] as! String
                self.store = Store(storeID: storeID, name: storeName, storeLogo: URL(string: storeLogo)!, storeBackground: URL(string: storeBackground)!, description: storeDescription, latitude: latitude, longitude: longitude)
            }
        }
        
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
