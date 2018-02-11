//
//  HelperFunctions.swift
//  Blip
//
//  Created by Srikanth Srinivas on 12/31/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation

class HelperFunctions{
    
    
    func MD5(string: String) -> String {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
