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
    var jobID: String!
    var ref: DatabaseReference!
    var locList = [CLLocationCoordinate2D]()
    
    init?(snapshot: DataSnapshot) {
        guard !snapshot.key.isEmpty else {
            return nil
        }
        let jobValues = snapshot.value as? [String:AnyObject]
        let deliveriesSnap = snapshot.childSnapshot(forPath: "deliveries")
        for snap in (deliveriesSnap.value as? [String: AnyObject])!{
            let delivery = Delivery(snapshot: deliveriesSnap.childSnapshot(forPath: "\(snap.key)"))
            self.locList.append(delivery?.origin)
            self.locList.append((delivery?.deliveryLocation)!)
            self.deliveries.append(delivery!)
        }
    
        self.ref = snapshot.ref
        self.jobID = snapshot.key
        
    }
}











