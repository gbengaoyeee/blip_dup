//
//  MyAPIClient.swift
//  Blip
//
//  Created by Srikanth Srinivas on 12/23/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import Firebase
import FirebaseDatabase

class MyAPIClient: NSObject, STPEphemeralKeyProvider {
    
    let service = ServiceCalls()
    var customer_id: String?
    static let sharedClient = MyAPIClient()
    var baseURLString: String? = "https://us-central1-blip-c1e83.cloudfunctions.net/"
    var baseURL: URL{
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        service.getCustomerID { (customer) in
            self.customer_id = customer
            Alamofire.request(url, method: .post, parameters: [
                "api_version": apiVersion,
                "customerID": self.customer_id!
                ])
                .validate(statusCode: 200..<300)
                .responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(let json):
                        completion(json as? [String: AnyObject], nil)
                    case .failure(let error):
                        completion(nil, error)
                        
                    }
            }
        }
        
    }
    
    enum CustomerKeyError: Error {
        case missingBaseURL
        case invalidResponse
    }
    
    func authorizeCharge(amount: Int,
                        completion: @escaping (String?) -> ()) {
        
        service.getCustomerID { (customer) in
            let email = Auth.auth().currentUser?.email
            self.customer_id = customer
            let url = self.baseURL.appendingPathComponent("charges")
            let params: [String: Any] = [
                "customerID": self.customer_id!,
                "amount": amount,
                "currency": "CAD",
                "email_hash": email!
            ]
            Alamofire.request(url, method: .post, parameters: params)
                .validate(statusCode: 200..<300)
                .responseString { response in
                    switch response.result {
                    case .success:
                        completion(response.value!)
                    case .failure:
                        completion(nil)
                    }
            }
        }//End of get customer closure
        
    }
    
    func completeCharge(job: Job, completion: @escaping(String?) -> ()){
        
        service.getChargeIDFor(job: job) { (id) in
            
            let url = self.baseURL.appendingPathComponent("captureCharge")
            let params: [String: Any] = [
                "chargeID": id
            ]
            Alamofire.request(url, method: .post, parameters: params)
                .validate(statusCode: 200..<300)
                .responseString { response in
                    switch response.result {
                    case .success:
                        completion(response.value!)
                    case .failure:
                        completion(nil)
                    }
        
            }
        }
    }
    
    func getCurrentCustomer(completion: @escaping STPJSONResponseCompletionBlock) {

        service.getCustomerID { (customer) in
            self.customer_id = customer
            let url = self.baseURL.appendingPathComponent("getCustomer")
            let params: [String: Any] = [
                "customerID": self.customer_id!
            ]
            
            Alamofire.request(url, method: .post, parameters: params)
                .validate(statusCode: 200..<300)
                .responseJSON { responseJSON in
                    switch responseJSON.result {
                    case .success(let json):
                        completion(json as? [String: AnyObject], nil)
                    case .failure(let error):
                        completion(nil, error)
                        
                    }
            }
        }
        
    }
    
    func updateCustomerDefaultSource(id source_id: String, completion: @escaping STPErrorBlock) {
        service.getCustomerID { (customer) in
            self.customer_id = customer
            let url = self.baseURL.appendingPathComponent("updateStripeCustomerDefaultSource")
            let params: [String: Any] = [
                "customerID": self.customer_id!,
                "source": source_id
            ]
            Alamofire.request(url, method: .post, parameters: params)
                .validate(statusCode: 200..<300)
                .responseString { response in
                    switch response.result {
                    case .success:
                        completion(nil)
                    case .failure(let error):
                        completion(error)
                    }
            }
        }
        
    }
    
    func createPaymentSource(cardName: String, cardNumber: String, cardExpMonth: UInt, cardExpYear: UInt, cardCVC: String, completion: @escaping STPSourceCompletionBlock) {
        let cardParams = STPCardParams()
        cardParams.name = cardName
        cardParams.number = cardNumber
        cardParams.expMonth = cardExpMonth
        cardParams.expYear = cardExpYear
        cardParams.cvc = cardCVC
        
        let sourceParams = STPSourceParams.cardParams(withCard: cardParams)
        STPAPIClient.shared().createSource(with: sourceParams, completion: completion)
    }
    
    func addPaymentSource(id source_id: String, completion: @escaping STPErrorBlock) {
        service.getCustomerID { (customer) in
            self.customer_id = customer
            let url = self.baseURL.appendingPathComponent("addNewPaymentSource")
            let params: [String: Any] = [
                "customerID": self.customer_id!,
                "sourceID": source_id
            ]
            Alamofire.request(url, method: .post, parameters: params)
                .validate(statusCode: 200..<300)
                .responseString { response in
                    switch response.result {
                    case .success:
                        completion(nil)
                    case .failure(let error):
                        completion(error)
                    }
            }
        }
        
    }
}
