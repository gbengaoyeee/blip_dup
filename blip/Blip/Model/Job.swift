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
        guard snapshot.key == "deliveries" || !snapshot.key.isEmpty else {
            return nil
        }
        if type == "delivery"{
            let jobValues = snapshot.value as? [String:AnyObject]
            for value in jobValues!{
                let deliveryValues = value.value as? [String: AnyObject]
                let id = value.key
                let deliveryLocation = CLLocationCoordinate2D(latitude: deliveryValues!["deliveryLat"] as! Double, longitude: deliveryValues!["deliveryLong"] as! Double)
                let origin = CLLocationCoordinate2D(latitude: deliveryValues!["originLat"] as! Double, longitude: deliveryValues!["originLong"] as! Double)
                let recieverName = deliveryValues!["recieverName"] as! String
                let recieverNumber = deliveryValues!["recieverNumber"] as! String
                let instructions = deliveryValues!["instructions"] as! String
                let delivery = Delivery(deliveryLocation: deliveryLocation, identifier: id, origin: origin, recieverName: recieverName, recieverNumber: recieverNumber, instructions: instructions)
                self.locList.append((delivery.origin)!)
                self.locList.append((delivery.deliveryLocation)!)
                self.deliveries.append(delivery)
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
}











