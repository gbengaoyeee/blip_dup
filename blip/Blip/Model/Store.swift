//
//  Store.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/29/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import Foundation
import Firebase
import Kingfisher

class Store {
    
    var name: String!
    var storeLogo: UIImage!
    var storeBackground: UIImage!
    var description: String!
    
    init(name: String, storeLogo: UIImage, storeBackground: UIImage, description: String) {
        
        self.name = name
        self.storeLogo = storeLogo
        self.storeBackground = storeBackground
        self.description = description
    }
    
    init?(snapshot: DataSnapshot) {
        guard snapshot.key == "store" else {
            return nil
        }
        let storeValues = snapshot.value as? [String: AnyObject]
        self.name = storeValues!["name"] as? String
        KingfisherManager.shared.retrieveImage(with: URL(string: (storeValues!["storeLogoURL"] as? String)!)!, options: nil, progressBlock: nil) { (image, error, cache, url) in
            if error != nil{
                print(error!)
            }
            else{
                if let image = image{
                    self.storeLogo = image
                }
            }
        }
        KingfisherManager.shared.retrieveImage(with: URL(string: (storeValues!["storeBackgroundURL"] as? String)!)!, options: nil, progressBlock: nil) { (image, error, cache, url) in
            if error != nil{
                print(error!)
            }
            else{
                if let image = image{
                    self.storeBackground = image
                }
            }
        }
        self.description = storeValues!["description"] as? String
    }
}
