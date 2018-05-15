//
//  Store.swift
//  Blip
//  Created by Srikanth Srinivas on 4/29/18.
//  Created by Gbenga Ayobami on 2018-04-30.
//  Copyright © 2018 Blip. All rights reserved.

import Foundation
import Firebase
import Kingfisher
import Mapbox


class Store {
    
    var name: String!
    var storeID:String
    var storeLogo: URL!
    var storeBackground: URL!
    var description: String!
    var location:CLLocationCoordinate2D!

    
    init(storeID:String, name: String, storeLogo: URL, storeBackground: URL, description: String, latitude:CLLocationDegrees, longitude:CLLocationDegrees) {
        self.name = name
        self.storeLogo = storeLogo
        self.storeBackground = storeBackground
        self.description = description
        self.storeID = storeID
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
//    init(storeID:String) {
//        let storesRef = Database.database().reference(withPath: "stores/\(storeID)")
//        storesRef.observeSingleEvent(of: .value) { (snapshot) in
//            guard let values = snapshot.value as? [String:Any] else{
//                print("Couldn't create the store")
//                return
//            }
//            self.name = values["storeName"] as! String
//            self.storeID = storeID
//            let storeLogoUrl = values["storeLogo"] as! String
//            let storeBackgroundUrl = values["storeBackground"] as! String
//            self.storeLogo = URL(string: storeLogoUrl)
//            self.storeBackground = URL(string: storeBackgroundUrl)
//            self.description = values["description"] as! String
//
//        }//End of observe
//    }
}
