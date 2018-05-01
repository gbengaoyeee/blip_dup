//
//  Store.swift
//  Blip
//  Created by Srikanth Srinivas on 4/29/18.
//  Created by Gbenga Ayobami on 2018-04-30.
//  Copyright © 2018 Blip. All rights reserved.

import Foundation
import Firebase
import Kingfisher


class Store {
    
    var name: String!
    var storeLogo: URL!
    var storeBackground: URL!
    var description: String!

    
    init(name: String, storeLogo: URL, storeBackground: URL, description: String) {
        self.name = name
        self.storeLogo = storeLogo
        self.storeBackground = storeBackground
        self.description = description
    }
}
