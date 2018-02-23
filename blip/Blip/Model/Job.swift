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
    
    var jobOwnerPhotoURL: URL?
    let description: String
    var title: String
    var wage_per_hour: Double
    var maxTime: Double
    var jobID: String!
    var location: CLLocation!
//    static var jobIDarray = [String]()
    var jobTakerID: String!
    var jobOwnerEmailHash: String!
    var jobOwnerFullName: String!
    var jobOwnerRating: Float?
    var ref: DatabaseReference!
    var latitude: Double!
    var longitude: Double!

    
    var placemark: CLPlacemark?
    var address: String!
    var addressDict:[String:String] = [:]

    init?(snapshot: DataSnapshot) {
        guard !snapshot.key.isEmpty,
            let jobValues = snapshot.value as? [String:AnyObject],
            let latitude = jobValues["latitude"] as? Double,
            let longitude = jobValues["longitude"] as? Double,
            let title = jobValues["jobTitle"] as? String,
            let description = jobValues["jobDescription"] as? String,
            let jobOwnerEmailHash = jobValues["jobOwner"] as? String,
            let jobOwnerFullName = jobValues["fullName"] as? String,
            let wage_per_hour = jobValues["price"] as? String,
            let maxTime = jobValues["time"] as? String
        else{return nil}
            
        
        
        
        self.ref = snapshot.ref
        self.jobID = snapshot.key
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.description = description
        self.jobOwnerEmailHash = jobOwnerEmailHash
        self.jobOwnerFullName = jobOwnerFullName
        self.wage_per_hour = Double(wage_per_hour)!
        self.maxTime = Double(maxTime)!
        self.location = CLLocation(latitude: latitude, longitude: longitude)

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self.location, completionHandler: { (placemarks, error) in
            if(error == nil){
                let placeMark = placemarks?[0]
                self.placemark = placeMark
                self.address = self.parseAddress(placemark: self.placemark!)
                print("ADDRESS: ", self.address)
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
        
        self.addressDict["address"] = addressLine
        return addressLine
    }

}











