//
//  BlipUser.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-01-27.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Firebase

class BlipUser{
    
    var userEmailHash:String?
    var email:String?
    var name: String?
    var rating: Double?
    var currentDevice: String?
    var customerID: String?
    var photoURL: URL?
    var uid: String?
    var completedJobs: [String:AnyObject]?
    var reviews: [String: Double]?
    var currentJobPost:Job?
    
    var ref:DatabaseReference!
    
    init?(snapFromJob: DataSnapshot){
        guard !snapFromJob.key.isEmpty else {
            return nil
        }
        let emailHashKey = snapFromJob.value as! [String: AnyObject]
        let userValues = snapFromJob.childSnapshot(forPath: emailHashKey.keys.first!).value as? [String:AnyObject]
        let email = userValues!["email"] as? String
        let name = userValues!["name"] as? String
        let rating = userValues!["rating"] as? Double
        let currentDevice = userValues!["currentDevice"] as? String
        let customerID = userValues!["customer_id"] as? String
        let photoURL = userValues!["photoURL"] as? String
        let uid = userValues!["uid"] as? String
        
        self.ref = snapFromJob.ref
        self.userEmailHash = snapFromJob.key
        self.email = email
        self.name = name
        self.rating = rating
        self.currentDevice = currentDevice
        self.customerID = customerID
        self.photoURL = URL(string: photoURL!)
        self.uid = uid
        
        if let userval = snapFromJob.value as? [String:AnyObject]{
            self.completedJobs = userval["CompletedJobs"] as? [String:AnyObject]
            self.reviews = userval["reviews"] as? [String:Double]
        }
    }
    
    init?(snapFromUser: DataSnapshot) {
        guard !snapFromUser.key.isEmpty else {
            return nil
        }
        let userValues = snapFromUser.value as? [String:AnyObject]
        let email = userValues!["email"] as? String
        let name = userValues!["name"] as? String
        let rating = userValues!["rating"] as? Double
        let currentDevice = userValues!["currentDevice"] as? String
        let customerID = userValues!["customer_id"] as? String
        let photoURL = userValues!["photoURL"] as? String
        let uid = userValues!["uid"] as? String
        
        self.ref = snapFromUser.ref
        self.userEmailHash = snapFromUser.key
        self.email = email
        self.name = name
        self.rating = rating
        self.currentDevice = currentDevice
        self.customerID = customerID
        self.photoURL = URL(string: photoURL!)
        self.uid = uid
        
        if let userval = snapFromUser.value as? [String:AnyObject]{
            self.completedJobs = userval["CompletedJobs"] as? [String:AnyObject]
            self.reviews = userval["reviews"] as? [String:Double]
            
        }
    }
}

