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

    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - storeID: <#storeID description#>
    ///   - name: <#name description#>
    ///   - storeLogo: <#storeLogo description#>
    ///   - storeBackground: <#storeBackground description#>
    ///   - description: <#description description#>
    ///   - latitude: <#latitude description#>
    ///   - longitude: <#longitude description#>
    init(storeID:String, name: String, storeLogo: URL, storeBackground: URL, description: String, latitude:CLLocationDegrees, longitude:CLLocationDegrees) {
        self.name = name
        self.storeLogo = storeLogo
        self.storeBackground = storeBackground
        self.description = description
        self.storeID = storeID
        self.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
