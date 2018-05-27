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
import Kingfisher

class Job{
    
    var deliveries = [Delivery]()
    var ref: DatabaseReference!
    var locList = [CLLocationCoordinate2D]()
    var unfinishedLocList = [CLLocationCoordinate2D]()
    var name: String!
    var description: String!
    var earnings: Double!
    var duration: Double!
    var otherTypeLocation: CLLocationCoordinate2D!
    var jobImages = [UIImage]()
    var otherJobID: String!
    
    init?(snapshot: DataSnapshot, type: String) {
        guard type == "delivery" || type == "other" else {
            return nil
        }
        guard snapshot.key == "givenJobs" || !snapshot.key.isEmpty else {
            return nil
        }
        if type == "delivery"{
            let jobValues = snapshot.value as? [String:AnyObject]
            for value in jobValues!{
                let id = value.key
                let delivery = Delivery(snapshot: snapshot.childSnapshot(forPath: id))
                if let delivery = delivery{
                    if delivery.state != nil{
                        self.unfinishedLocList.append(delivery.deliveryLocation)
                    }
                    else{
                        self.locList.append(delivery.origin)
                        self.locList.append(delivery.deliveryLocation)
                    }
                    self.deliveries.append(delivery)
                }
            }
            for location in unfinishedLocList{
                locList.append(location)
            }
        }
        
        else{
            if let jobValues = snapshot.value as? [String:AnyObject]{
                self.name = jobValues["name"] as? String
                self.description = jobValues["description"] as? String
                self.duration = jobValues["duration"] as? Double
                self.earnings = jobValues["earnings"] as? Double
                self.otherJobID = snapshot.key
                self.otherTypeLocation = CLLocationCoordinate2D(latitude: jobValues["locationLat"] as! Double, longitude: jobValues["locationLong"] as! Double)
                for value in jobValues["imageURLs"] as! [String]{
                    KingfisherManager.shared.retrieveImage(with: URL(string: value)!, options: nil, progressBlock: nil) { (image, error, type, url) in
                        if let image = image{
                            self.jobImages.append(image)
                        }
                    }
                }
            }
        }
    
        self.ref = snapshot.ref
    }
    
    func getUnfinishedDeliveries() -> [Delivery]{
        
        var unfinishedDeliveries = [Delivery]()
        for delivery in self.deliveries{
            if delivery.state != nil{
                unfinishedDeliveries.append(delivery)
            }
        }
        return unfinishedDeliveries
    }
}











