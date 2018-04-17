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
    var ref: DatabaseReference!
    var locList = [CLLocationCoordinate2D]()
    
    init?(snapshot: DataSnapshot) {
        guard snapshot.key == "deliveries" else {
            return nil
        }
        let jobValues = snapshot.value as? [String:AnyObject]
        for value in jobValues!{
            let deliveryValues = value.value as? [String: AnyObject]
            let id = value.key
            let deliveryLocation = CLLocationCoordinate2D(latitude: deliveryValues!["deliveryLat"] as! Double, longitude: deliveryValues!["deliveryLong"] as! Double)
            let origin = CLLocationCoordinate2D(latitude: deliveryValues!["originLat"] as! Double, longitude: deliveryValues!["originLong"] as! Double)
            let recieverName = deliveryValues!["recieverName"] as! String
            let recieverNumber = deliveryValues!["recieverNumber"] as! String
            let delivery = Delivery(deliveryLocation: deliveryLocation, identifier: id, origin: origin, recieverName: recieverName, recieverNumber: recieverNumber)
            self.locList.append((delivery.origin)!)
            self.locList.append((delivery.deliveryLocation)!)
            self.deliveries.append(delivery)
        }
    
        self.ref = snapshot.ref
    }
}











