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
import FirebaseDatabase

class MyAPIClient: NSObject {
    
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
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil)
            .responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    let jsonData = json as? [String: AnyObject]
                    if jsonData!["code"] as! String == "InvalidInput"{
                        enum invalidInput: Error {
                            case runtimeError(String)
                        }
                        completion(nil, nil, invalidInput.runtimeError("Invalid Input error"))
                    }
                    else{
                        let waypointData = jsonData!["waypoints"] as? [[String: AnyObject]]
                        let routeData = jsonData!["trips"] as? [[String: AnyObject]]
                        let route = routeData![0]
                        completion(waypointData, route, nil)
                    }
                case .failure(let error):
                    completion(nil, nil, error)
                }
        }
    }
    
    func verifyStripeAccount(routingNumber: String!, accountNumber: String!, city: String!, streetAdd: String!, postalCode: String!, province: String!, sin: String!, dobMonth: String, dobDay: String, dobYear: String, completion: @escaping([String: AnyObject]?, String?) -> ()){
        let url = self.baseURL.appendingPathComponent("updateStripeAccount")
        service.retrieveStripeAccount { (account) in
            if let account = account{
                let params: [String: Any] = [
                    "emailHash": self.service.emailHash!,
                    "account_ID": account,
                    "routing_number": routingNumber!,
                    "account_number": accountNumber!,
                    "city": city!,
                    "line1": streetAdd!,
                    "dob_day": dobDay,
                    "dob_month": dobMonth,
                    "dob_year": dobYear,
                    "postal_code": postalCode!,
                    "state": province!,
                    "sin": sin!,
                    "tos_time": "\(Int(NSDate().timeIntervalSince1970.rounded()))"]
            
                Alamofire.request(url, method: .post, parameters: params, headers: nil)
                    .validate(statusCode: 200..<300)
                    .responseString { (response) in
                    print("response", response)
                    switch response.result {
                    case .success:
                        print("Successful verification")
                        completion(nil, nil)
                    case .failure:
                        print(response.result.value)
                        completion(nil, response.result.value)
                    }
                }
            }
        }
    }
    
    func getAccountBalance(emailHash: String, completion: @escaping(String?) -> ()) {
        
        let url = self.baseURL.appendingPathComponent("getAccountBalance")
        let params: [String: Any] = [
            "emailHash": emailHash
        ]
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { (resp) in
                switch resp.result{
                case .success:
                    if let response = resp.result.value{
                        completion(response)
                    }
                case .failure:
                    print(resp.result.value)
                    completion(nil)
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
    
    func getBestJobAt(location: CLLocationCoordinate2D, userHash: String, completion: @escaping(Int?,Bool?) -> ()){
        let locationLat = Double(location.latitude)
        let locationLong = Double(location.longitude)
        let url = self.baseURL.appendingPathComponent("getBestJob")
        let params: [String: Any] = [
            "locationLat" : locationLat,
            "locationLong" : locationLong,
            "emailHash" : userHash
        ]
        
        Auth.auth().currentUser?.reload(completion: { (err) in
            if err != nil{
                print("Error reloading current user")
                return
            }
            Alamofire.request(url, method: .post, parameters: params, headers: nil).validate(statusCode: 200...200)
                .responseString { (resp) in
                    switch resp.result{
                    case .success:
                        print("Result:", resp.result.value)
                        print("Result:", resp.response?.statusCode)
                        completion(nil, true)
                        break
                    case .failure(let error):
                        print("Result:",resp.result)
                        print("Result:",resp.response?.statusCode)
                        completion(resp.response?.statusCode, nil)
                        break
                    }
            }
        })
        

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
    
    enum CustomerKeyError: Error {
        case missingBaseURL
        case invalidResponse
    }
    
    func getStore(storeID:String, completion:@escaping ([String:Any]?,Error?)->()){
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        let params = [
            "storeID":storeID
        ]
        Alamofire.request(url, method: .get, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .validate(statusCode: 200...200)
            .responseJSON { (response) in
                switch response.result{
                case .success(let json):
                    let result = json as! [String:Any]
                    completion(result, nil)
                    break
                case .failure(let error):
                    completion(nil, error)
                    break
                }
        }
    }
    
    
    func makeDeliveryRequest(storeID:String, deliveryLat:Double, deliveryLong:Double, deliveryMainInstruction:String, deliverySubInstruction:String, originLat:Double, originLong:Double, pickupMainInstruction:String, pickupSubInstruction:String, recieverName:String, recieverNumber:String, pickupNumber:String){
        
        let url = self.baseURL.appendingPathComponent("makeDeliveryRequest")
        let params:[String:Any] = [
            "storeID":storeID,
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
}
