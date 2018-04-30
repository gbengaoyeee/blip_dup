//
//  Store.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-30.
//  Copyright © 2018 Blip. All rights reserved.
//

import Foundation
import Firebase

class Store {
    
    var name: String!
    var storeLogo: URL!
    var storeBackground: URL!
    var minOrder: Float!
    var description: String!
    var category: String!
    
    init(name: String, storeLogo: URL, storeBackground: URL, minOrder: Float, category: String, description: String) {
        self.minOrder = minOrder
        self.name = name
        self.storeLogo = storeLogo
        self.storeBackground = storeBackground
        self.description = description
        self.category = category
    }
    
}
