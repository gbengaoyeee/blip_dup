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
    var baseURLString: String? = "https://us-central1-blip-test-ios.cloudfunctions.net/"
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
    
    func createCourier(firstName: String, lastName: String, phoneNumber: String, email: String, password: String, completion: @escaping(String) -> ()){
        let params = [
            "firstName": firstName,
            "lastName": lastName,
            "password": password,
            "confirmPassword": password,
            "email": email,
            "phoneNumber": phoneNumber,
            "photoURL": "https://firebasestorage.googleapis.com/v0/b/blip-c1e83.appspot.com/o/profiledefault.png?alt=media&token=48d32bdd-69fe-4ca3-975a-e578ab36c9c7"
        ]
        let url = self.baseURL.appendingPathComponent("createCourier")
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .validate(statusCode: 200..<200)
            .response { (response) in
                if response.response?.statusCode == 200{
                    completion("200")
                }
                else if response.response?.statusCode == 400{
                    completion("Blank Fields")
                }
                else{
                    completion("default")
                }
        }
    }
    
    func getPathTime(coordinates: [CLLocationCoordinate2D], completion: @escaping(Int) -> ()){
        var waypointString = "&waypoints="
        var url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(coordinates.first!.latitude),\(coordinates.first!.longitude)&destination=\(coordinates.last!.latitude),\(coordinates.last!.longitude)"
        if coordinates.count > 2{
            waypointString += "\(coordinates[1].latitude),\(coordinates[1].longitude)|"
            waypointString += "\(coordinates[2].latitude),\(coordinates[2].longitude)"
            url += "\(waypointString)&key=AIzaSyAOQy-AvLrLjqQlXNi533HNzWLKvEqqq-o"
            
        }
        else{
            url += "&key=AIzaSyAOQy-AvLrLjqQlXNi533HNzWLKvEqqq-o"
        }
        let stringURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let directionsURL = URL(string: stringURL!)
        Alamofire.request(directionsURL!, method: .post, parameters: nil, headers: nil)
            .validate(statusCode: 200...200)
            .responseJSON { (data) in
                switch data.result{
                case .success(let rawData):
                    if let rawDict = rawData as? [String: Any]{
                        if let routeData = rawDict["routes"] as? [Any]{
                            if let firstRoute = routeData[0] as? [String: Any]{
                                if let legData = firstRoute["legs"] as? [Any]{
                                    if let firstLeg = legData[0] as? [String: Any]{
                                        if let durationData = firstLeg["duration"] as? [String: Any]{
                                            if let duration = durationData["value"] as? Int{
                                                let timeInSeconds = duration
                                                completion(timeInSeconds)
                                            }
                                            else{
                                                completion(-1)
                                            }
                                        }
                                        else{
                                            completion(-1)
                                        }
                                    }
                                    else{
                                        completion(-1)
                                    }
                                }
                                else{
                                    completion(-1)
                                }
                            }
                            else{
                                completion(-1)
                            }
                        }
                        else{
                            completion(-1)
                        }
                    }
                    else{
                        completion(-1)
                    }
                case .failure(let error):
                    print(error)
                    completion(-1)
                }
        }
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
                    break
                case .failure(let error):
                    completion(nil, nil, error)
                    break
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
                        break
                    case .failure:
                        completion(nil, response.result.value)
                        break
                    }
                }
            }
        }
    }
    
    func sendSms(phoneNumber:String, message:String){
        let url = self.baseURL.appendingPathComponent("sendSms")
        let param = [
            "phoneNumber":phoneNumber,
            "message":message
        ]
        Alamofire.request(url, method: .post, parameters: param, headers: nil).validate(statusCode: 200...200)
            .responseString { (response) in
                switch response.result {
                case .success:
                    print("Message sent successfully")
                    break
                case .failure:
                    print("Error sending message to the user")
                    break
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
                    break
                case .failure:
                    completion(nil)
                    break
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
                        completion(nil, true)
                        break
                    case .failure( _):
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
    
    
    func makeDeliveryRequest(storeID:String, deliveryAddress: String, deliveryMainInstruction:String, deliverySubInstruction:String, pickupAddress:String, pickupMainInstruction:String, pickupSubInstruction:String, recieverName:String, recieverNumber:String, pickupNumber:String){
        
        let url = self.baseURL.appendingPathComponent("makeDeliveryRequest")
        let params:[String:Any] = [
            "storeID":storeID,
            "deliveryAddress":deliveryAddress,
            "pickupAddress":pickupAddress,
            "deliveryMainInstruction":deliveryMainInstruction,
            "deliverySubInstruction":deliverySubInstruction,
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
