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
import CoreLocation
import Firebase
import MapboxDirections
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import FirebaseDatabase

class MyAPIClient: NSObject, STPEphemeralKeyProvider {
    
    let service = ServiceCalls.instance
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
    
    ///Converts all the coordinates of the locations into a string format: "longitude,latitude;longitude,latitude"
    private func convertLocationToString(locations:[CLLocationCoordinate2D])->String{
        var str = ""
        for loc in locations{
            str = str + "\(loc.longitude),\(loc.latitude);"
        }
        let retStr = String(str.dropLast())
        return retStr
        
    }
    
    func optimizeRoute(locations: [CLLocationCoordinate2D], distributions: String, completion: @escaping ([[String: AnyObject]]?,[String: AnyObject]?, Error?) -> ()){
        let coords = convertLocationToString(locations: locations)
        let url = "https://api.mapbox.com/optimized-trips/v1/mapbox/driving/\(coords)?&distributions=\(distributions)&geometries=geojson&access_token=pk.eyJ1Ijoic3Jpa2FudGhzcm52cyIsImEiOiJjajY0NDI0ejYxcDljMnFtcTNlYWliajNoIn0.jDevn4Fm6WBZUx7TDtys9Q"
        print(url)
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil)
            .responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    let jsonData = json as? [String: AnyObject]
                    let waypointData = jsonData!["waypoints"] as? [[String: AnyObject]]
                    let routeData = jsonData!["trips"] as? [[String: AnyObject]]
                    let route = routeData![0]
                    completion(waypointData, route, nil)
                case .failure(let error):
                    completion(nil, nil, error)
                }
        }
    }
    
    func verifyStripeAccount(routingNumber: String!, accountNumber: String!, city: String!, streetAdd: String!, postalCode: String!, province: String!, dobDay: String!, dobMonth: String!, dobYear: String!, firstName: String!, lastName: String!, sin: String!, completion: @escaping([String: AnyObject]?, Error?) -> ()){
        let url = self.baseURL.appendingPathComponent("updateStripeAccount")
        service.retrieveStripeAccount { (account) in
            if let account = account{
                let params: [String: Any] = [
                    "emailHash": self.service.emailHash!,
                    "account_ID": account,
                    "routing_number": "11000-000",
                    "account_number": "000123456789",
                    "city": "Mississauga", "line1": "156 enfield",
                    "postal_code": "l5b4l8",
                    "state": "ON",
                    "dob_day": "01",
                    "dob_month": "01",
                    "dob_year": "1996",
                    "first_name": "srikanth",
                    "last_name": "srinivas",
                    "sin": "000000000",
                    "tos_time": "\(Int(NSDate().timeIntervalSince1970.rounded()))"]
            
                Alamofire.request(url, method: .post, parameters: params, headers: nil).responseJSON { (response) in
                    print("response", response)
                    switch response.result {
                    case .success(let json):
                        print(json)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            
        }
        
    }
    
    func getNumberOfJobsNearMe(location: CLLocationCoordinate2D, completion: @escaping(Int?) -> ()){
        
        let locationLat = Double(location.latitude)
        let locationLong = Double(location.longitude)
        let url = self.baseURL.appendingPathComponent("getNumberOfJobs")
        let params: [String: Any] = [
            "locationLat" : locationLat,
            "locationLong" : locationLong
        ]
        Alamofire.request(url, method: .post, parameters: params)
    }
    
    func getBestJobAt(location: CLLocationCoordinate2D, userHash: String, completion: @escaping(Error?,Bool?) -> ()){
        let locationLat = Double(location.latitude)
        let locationLong = Double(location.longitude)
        let url = self.baseURL.appendingPathComponent("getBestJob")
        let params: [String: Any] = [
            "locationLat" : locationLat,
            "locationLong" : locationLong,
            "emailHash" : userHash
        ]
        Alamofire.request(url, method: .post, parameters: params, headers: nil).validate(statusCode: 200..<300)
            .responseString { (resp) in
                switch resp.result{
                case .success:
                    if resp.result.value != "No job found"{
                        print("Result:", resp.result.value)
                        completion(nil, true)
                    }else{
                        print("Result:", resp.result.value)
                        completion(nil, false)
                    }
                case .failure(let error):
                    completion(error, nil)
                }
        }
//        Alamofire.request(url, method: .get, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { (resp) in
//            print("DATA IS:",resp)
//        }
    }
    
    func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options = JSONSerialization.WritingOptions.prettyPrinted
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        } catch {
            print(error)
        }
        
        return ""
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
    
    func testStoreCreation(){
        
    }
    
    func postTestJob(storeName:String, deliveryLat:Double, deliveryLong:Double, deliveryMainInstruction:String, deliverySubInstruction:String, originLat:Double, originLong:Double, pickupMainInstruction:String, pickupSubInstruction:String, recieverName:String, recieverNumber:String, pickupNumber:String){
        
        let url = self.baseURL.appendingPathComponent("postTestJob")
        let params:[String:Any] = [
            "storeName":storeName,
            "deliveryLat":deliveryLat,
            "deliveryLong":deliveryLong,
            "deliveryMainInstruction":deliveryMainInstruction,
            "deliverySubInstruction":deliverySubInstruction,
            "originLat":originLat,
            "originLong":originLong,
            "pickupMainInstruction":pickupMainInstruction,
            "pickupSubInstruction":pickupSubInstruction,
            "recieverName":recieverName,
            "recieverNumber":recieverNumber,
            "pickupNumber":pickupNumber
        ]
        Alamofire.request(url, method: .post, parameters: params, headers: nil).validate(statusCode: 200...200)
            .responseString { (response) in
                switch response.result{
                case .success:
                    print(response.result)
                    break
                case .failure:
                    print(response.result)
                    break
                }
        }
    }
    
    func createNewStripeAccount(email:String, firstName:String, lastName:String, completion:@escaping (String?, Error?)->()){
        let url = self.baseURL.appendingPathComponent("createNewStripeAccount")
        let params:[String:Any] = [
            "email":email,
            "firstName":firstName,
            "lastName":lastName
        ]
        Alamofire.request(url, method: .post, parameters: params, headers: nil).validate(statusCode: 200..<300)
            .responseString { (response) in
                switch response.result{
                case .success:
                    completion(response.value, nil)
                    break
                case .failure(let error):
                    completion(nil, error)
                    break
                }
        }
    }
    
    func authorizeCharge(amount: Int, completion: @escaping (String?) -> ()) {
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
        
//        service.getChargeIDFor(job: job) { (id) in
//            
//            let url = self.baseURL.appendingPathComponent("captureCharge")
//            let params: [String: Any] = [
//                "chargeID": id
//            ]
//            Alamofire.request(url, method: .post, parameters: params)
//                .validate(statusCode: 200..<300)
//                .responseString { response in
//                    switch response.result {
//                    case .success:
//                        completion(response.value!)
//                    case .failure:
//                        completion(nil)
//                    }
//        
//            }
//        }
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
