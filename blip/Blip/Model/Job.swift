//
//  Job.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2017-06-14.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Firebase
import MapKit


class Job{
    
    var deliveries = [Delivery]()
    var orderer: BlipUser!
    var title: String!
    var pickupLocationCoordinates: CLLocationCoordinate2D!
    var earnings: Double!
    var estimatedTime: Double!
    var jobID: String!
    var ref: DatabaseReference!
    var pickupPlacemark: CLPlacemark!
    var pickupAddress: String!
    var ordererSnapRef: DatabaseReference?
    var locList = [CLLocationCoordinate2D]()
    
    init?(snapshot: DataSnapshot) {
        guard !snapshot.key.isEmpty else {
            return nil
        }
        let jobValues = snapshot.value as? [String:AnyObject]
        let deliveriesSnap = snapshot.childSnapshot(forPath: "deliveries")
        for snap in (deliveriesSnap.value as? [String: AnyObject])!{
            let delivery = Delivery(snapshot: deliveriesSnap.childSnapshot(forPath: "\(snap.key)"))
            self.locList.append((delivery?.deliveryLocation)!)
            self.deliveries.append(delivery!)
        }
        
        let pickupLatitude = jobValues!["pickupLocationLat"] as? Double
        let pickupLongitude = jobValues!["pickupLocationLong"] as? Double
        let title = jobValues!["jobTitle"] as? String
        let orderer = BlipUser(snapFromJob: snapshot.childSnapshot(forPath: "orderer"))
        let earnings = jobValues!["earnings"] as? Double
        let estimatedTime = jobValues!["estimatedTime"] as? Double
    
        self.ref = snapshot.ref
        self.jobID = snapshot.key
        self.title = title
        self.orderer = orderer
        self.pickupLocationCoordinates = CLLocationCoordinate2D(latitude: pickupLatitude!, longitude: pickupLongitude!)
        self.locList.insert(pickupLocationCoordinates, at: 0)
        self.earnings = earnings
        self.estimatedTime = estimatedTime
        self.ordererSnapRef = snapshot.childSnapshot(forPath: "orderer").ref
        
        // Setting the address string of the job
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: (self.pickupLocationCoordinates?.latitude)!, longitude: (self.pickupLocationCoordinates?.longitude)!), completionHandler: { (placemarks, error) in
            if(error == nil){
                let placeMark = placemarks?[0]
                self.pickupPlacemark = placeMark
                self.pickupAddress = self.parseAddress(placemark: self.pickupPlacemark!)
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











