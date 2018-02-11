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

    }
    
    

}











