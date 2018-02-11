//
//  CustomAPIAdapter.swift
//  Blip
//
//  Created by Srikanth Srinivas on 12/26/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import Stripe


class CustomAPIAdapter: NSObject, STPBackendAPIAdapter {
    
    
    func retrieveCustomer(_ completion: STPCustomerCompletionBlock? = nil) {
        MyAPIClient.sharedClient.getCurrentCustomer { (dict, err) in
            completion!(STPCustomer.decodedObject(fromAPIResponse: dict), err);
        }
    }
    
    func attachSource(toCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        MyAPIClient.sharedClient.addPaymentSource(id: source.stripeID, completion: completion)
    }
    
    func selectDefaultCustomerSource(_ source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        MyAPIClient.sharedClient.updateCustomerDefaultSource(id: source.stripeID, completion: completion)
    }
}
