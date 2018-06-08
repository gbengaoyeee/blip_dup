//
//  DataBase.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2017-06-22.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//


import Foundation
import UIKit
import CoreLocation
import Firebase
import Mapbox
import Alamofire

typealias CreateUserCompletion = (_ errorMsg: String?, _ data: AnyObject?) ->Void

class ServiceCalls{
    private static var _instance:ServiceCalls{
        return ServiceCalls()
    }
    
    static var instance: ServiceCalls{
        return _instance
    }
    
    var emailHash:String!
    private var dbRef:DatabaseReference!{
        return Database.database().reference()
    }
    
    private var jobsRef: DatabaseReference!{
        return Database.database().reference().child("AllJobs")
    }
    private var userRef: DatabaseReference!{
        return Database.database().reference().child("Couriers")
    }
    
    private var completedJobsRef: DatabaseReference!{
        return Database.database().reference(withPath: "/CompletedJobs")
    }
    
    private var storesRef: DatabaseReference!{
        return Database.database().reference(withPath: "/stores")
    }
    
    let userDefaults = UserDefaults.standard
    var availableJobs: [Job] = []
    let helper = HelperFunctions()
    
    var jobsRefHandle:DatabaseHandle!
    var userRefHandle: DatabaseHandle!
    var childHandle: DatabaseHandle!
    var currentBlipUser: BlipUser?
    var userCredDict:[String:String]!
    let loginCredentials = "loginCredentials"
    let userDefault = UserDefaults.standard
    var provider:String!
    
    init() {
        if let currentUser = Auth.auth().currentUser{
            self.emailHash = MD5(string: (currentUser.email)!)
        }
        if let providerData = Auth.auth().currentUser?.providerData {
            guard let provider = providerData.first?.providerID else{
                print("Couldnt get provider")
                return
            }
            self.provider = provider
        }
    }
    
    /// Checks user status
    ///
    /// - Parameter completion: Returns code 1 if the user is not verified, code 2 if flagged
    func checkUserVerifiedOrFlagged(completion: @escaping (Int)->()){
        self.userRef.child(emailHash).observeSingleEvent(of: .value) { (snap) in
            if let userValues = snap.value as? [String:Any]{
                let flagged = userValues["flagged"] as? Bool
                let verified = userValues["verified"] as? Bool
                if !(verified!){
                    completion(1)
                }
                else if (flagged != nil){
                    completion(2)
                }else{
                    completion(0)
                }
            }
        }
    }
    
    /// Finds a job for you, triggering the backend call
    ///
    /// - Parameters:
    ///   - myLocation: Your current location
    ///   - userHash: Your emailHash
    ///   - completion: returns 400 if your account is unverified, 500 if its flagged, 404 if no job has been found, or nil, with a job if its been found
    func findJob(myLocation: CLLocationCoordinate2D, userHash: String, completion: @escaping(Int?, Job?) -> ()){
        self.userRefHandle = userRef.child(emailHash).observe(.childAdded, with: { (snap) in
            if snap.key == "givenJob"{
                if let jobID = snap.value as? [String: AnyObject]{
                    let j = Job(snapshot: snap, type: "delivery")
                    j?.locList.insert(myLocation, at: 0)
                    self.userRef.removeObserver(withHandle: self.userRefHandle)
                    completion(nil, j)
                }
            }
        })
        
        MyAPIClient.sharedClient.getBestJobAt(location: myLocation, userHash: userHash) { (errorCode, found) in
            
            if errorCode != nil{

                if(errorCode == 400){//This is for fb users
                    self.removeFirebaseObservers()
                    completion(400, nil)//Not verified
                    return
                }
                else if errorCode == 500{
                    self.removeFirebaseObservers()
                    completion(500, nil)//Flagged
                    return
                }else{
                    self.removeFirebaseObservers()
                    completion(404, nil)// No job Found
                    return
                }
            }
        }
    }
    
    /// Removes firebase observers
    func removeFirebaseObservers(){
        userRef.child(emailHash).removeAllObservers()
        self.userRef.child(emailHash).child("givenJobs").removeAllObservers()
        print("Observers Removed")
    }
    
    
    /// Called upon completion of all jobs
    ///
    /// - Parameter completion: Triggers when all jobs complete updated in the database
    func completedAllJobs(completion: @escaping() -> ()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            guard let deliveries = snapshot.value as? [String: AnyObject] else{
                print("Couldn't get delivery jobs")
                return
            }
            self.userRef.child(self.emailHash).child("completedDeliveries").updateChildValues(deliveries)
            self.userRef.child(self.emailHash).child("givenJob").removeValue()
            completion()
        }
    }
    
    /// Called upon completion of a single job
    ///
    /// - Parameters:
    ///   - delivery: A delivery object
    ///   - type: Either a delivery or a pickup in string form
    ///   - deliveredTo: Who the delivery was delivered to if type == Delivery
    func completedJob(delivery:Delivery, type:String, deliveredTo: String? = nil){
        let deliveryID = delivery.identifier!
        let storeID = delivery.store.storeID
        if type == "Pickup"{
            let ref = Database.database().reference(withPath: "/Couriers/\(self.emailHash!)/givenJob/\(deliveryID)")
            let storeRef = Database.database().reference(withPath: "/stores/\(storeID)/deliveries/\(deliveryID)")
            ref.updateChildValues(["state":"pickup"])
            storeRef.updateChildValues(["state":"pickup"])
            //Text the receiver as soon as the pickup is complete
            let name = Auth.auth().currentUser!.displayName!
            let number = delivery.receiverPhoneNumber!
            let message = "\(name) has just picked up your parcel and is on their way to you. They will wait for up to 5 minutes before leaving"
            MyAPIClient.sharedClient.sendSms(phoneNumber: number, message: message)
            return
        }
        userRef.child(emailHash).child("givenJob").child(deliveryID).observeSingleEvent(of: .value) { (snapshot) in
            guard var values = snapshot.value as? [String:Any] else{
                print("Couldn't get values")
                return
            }
            values["deliveredTo"] = deliveredTo!
            values["isCompleted"] = true
            values["state"] = "delivery"
            let ref = Database.database().reference(withPath: "/Couriers/\(self.emailHash!)/givenJob/\(deliveryID)")
            let storeRef = Database.database().reference(withPath: "/stores/\(storeID)/deliveries/\(deliveryID)")
            storeRef.updateChildValues(values)
            self.completedJobsRef.child(deliveryID).updateChildValues(values)
            self.userRef.child(self.emailHash).child("completedDeliveries/\(deliveryID)").updateChildValues(values)
            ref.removeValue()
        }
    }
    
    /// Checks the reference in which you have jobs
    ///
    /// - Parameter completion: True if theres a job, false otherwise
    func checkGivenJobReference(completion: @escaping(Bool) -> ()){
        userRef.child(emailHash).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.hasChild("givenJob"){
                completion(true)
            }
            else{
                completion(false)
            }
        }
    }
    
    /// Sets isTaken on storeRef and userRef
    ///
    /// - Parameter waypointList: A list of BlipWaypoints to set isTaken to their respective delivery objects
    func setIsTakenOnGivenJobsAndStore(waypointList:[BlipWaypoint]){
        let ref = Database.database().reference(withPath: "Couriers/\(self.emailHash!)/givenJob")
        let storesRef = Database.database().reference(withPath: "stores")
        for way in waypointList{
            let time = Int(NSDate().timeIntervalSince1970.rounded())
            ref.child(way.delivery.identifier).updateChildValues(["isTaken":true, "jobTaker":self.emailHash!, "timeTaken": time])
            storesRef.child("\(way.delivery.store.storeID)/deliveries/\(way.delivery.identifier!)").updateChildValues(["isTaken":true, "jobTaker":self.emailHash!, "timeTaken": time])
        }
    }
    
    /// Loads all map annotations
    ///
    /// - Parameter map: The map on which to load the annotations
    func loadMapAnnotations(map: MGLMapView){
        jobsRef.observeSingleEvent(of: .value) { (snap) in
            let snapDict = snap.value as? [String: AnyObject]
            var x = 15
            if let snapDict = snapDict{
                for key in (snapDict.keys){
                    if let delivery = Delivery(snapshot:
                        snap.childSnapshot(forPath: key)){
                        if x == 0{
                            break
                        }
                        let annotation = MGLPointAnnotation()
                        annotation.coordinate = delivery.deliveryLocation
                        map.addAnnotation(annotation)
                        x -= 1
                    }
                }
                if var annotations = map.annotations{
                    if let user = map.userLocation{
                        annotations.append(user)
                    }
                    map.showAnnotations(annotations, animated: true)
                }
            }
        }
    }
    
    /// Create User in Firebase Authentication and sends verification email
    ///
    /// - Parameters:
    ///   - email: user email
    ///   - password: user password
    ///   - completion: returns upon completion of user object creation in firebase
    func createUser(firstName:String, lastName:String, email: String, password:String, image:UIImage?, completion: CreateUserCompletion?){
        Auth.auth().createUser(withEmail: email, password: password, completion: { (dataResult, error) in
            if error != nil{
                //Handling Firebase Errors
                self.handleFirebaseError(error: (error as NSError?)!, completion: completion)
                return
            }
            //No errors
            //Do whatever is needed
            
            self.emailHash = self.MD5(string: (dataResult?.user.email)!)
            self.addUserToDatabase(uid: (dataResult!.user.uid), firstName: firstName, lastName: lastName, email: email, provider: nil)
            //Send Email verification
            dataResult?.user.sendEmailVerification(completion: { (error) in
                if error != nil{
                    print(error!.localizedDescription)
                    self.handleFirebaseError(error: (error as NSError?)!, completion: completion)
                    return
                }
                print("SENT VERIFICATION")
                self.uploadProfileImage(name: "\(firstName) \(lastName)", image: image, completion: { (errMsg, uploaded) in
                    if errMsg != nil{
                        print("ERROR:",errMsg!)
                        return
                    }
                    completion?(nil, dataResult?.user)
                })
                
            })
            
        })
    }
    
    ///Add the new user's info into Database
    func addUserToDatabase(uid:String, firstName:String, lastName:String, email:String, provider: String?){
        if provider != nil{
            userRef.child(MD5(string: email)).observeSingleEvent(of: .value) { (snapshot) in
                if let values = snapshot.value as? [String:Any]{
                    if let granted = values["granted"] as? Bool{
                        if granted == true{
                            let dict:[String:Any] = ["granted":true, "uid":uid, "firstName":firstName, "lastName":lastName, "email":email, "rating":5.0, "currentDevice":AppDelegate.DEVICEID]
                            self.userRef.child(self.emailHash).updateChildValues(dict)
                            return
                        }
                    }
                    
                    let dict:[String:Any] = ["granted":true, "uid":uid, "firstName":firstName, "lastName":lastName, "email":email, "rating":5.0, "currentDevice":AppDelegate.DEVICEID, "verified":false]
                    self.userRef.child(self.emailHash).updateChildValues(dict)
                }
            }
        }else{
            let dict:[String:Any] = ["uid":uid, "firstName":firstName, "lastName":lastName, "email":email, "rating":5.0, "currentDevice":AppDelegate.DEVICEID, "verified":false]
            userRef.child(self.emailHash).updateChildValues(dict)
        }
    }
    
    /// Retrieves a stripe account
    ///
    /// - Parameter completion: An account ID if successful, nil otherwise
    func retrieveStripeAccount(completion: @escaping(String?) -> ()){
        userRef.child(emailHash).child("stripeAccount/id").observeSingleEvent(of: .value) { (snapshot) in
            if let accountID = snapshot.value as? String{
                completion(accountID)
            }
            else{
                completion(nil)
            }
        }
    }
    
    
    ///Upload profile image to firebase storage
    func uploadProfileImage(name:String, image:UIImage?, completion: CreateUserCompletion?){
        let storageRef = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/")
        let profileImgRef = storageRef.child("profile_image").child(emailHash)
        
        if let image = image, let imageData = UIImageJPEGRepresentation(image, 0.1){
            let uploadTask = profileImgRef.putData(imageData, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    print("MetaUh-oh, an error occurred!")
                    return
                }
                profileImgRef.downloadURL(completion: { (profileImgURL, error) in
                    guard let profileImgURL = profileImgURL else {
                        // Uh-oh, an error occurred!
                        print("OtherUh-oh, an error occurred!")
                        return
                    }
                    print("profileurl",profileImgURL.absoluteString)
                    let profile = Auth.auth().currentUser?.createProfileChangeRequest()
                    profile?.photoURL = profileImgURL
                    profile?.displayName = name
                    print("HERE 1")
                    profile?.commitChanges(completion: { (err) in
                        print("HERE 2")
                        if err != nil{
                            completion?(err!.localizedDescription, nil)
                            return
                        }
                        print("HERE 3")
                        let imgValues:[String:String] = ["photoURL":profileImgURL.absoluteString]
                        self.userRef.child(self.emailHash).updateChildValues(imgValues)
                        completion?(nil, nil)
                    })
                })
            }
        }
        else{
            let imgValues:[String:String] = ["photoURL":""]
            self.userRef.child(self.emailHash).updateChildValues(imgValues)
        }
    }
    
    /// Updates the device token of the current device
    func updateCurrentDeviceToken(){
        if let credentials = self.userDefaults.dictionary(forKey: "loginCredentials"){
            if let device = credentials["currentDevice"] as? String{
                print("TOKEN", device)
                let token = ["currentDevice": device]
                userRef.child(emailHash).updateChildValues(token)
            }
        }
    }
    
    /// Signs in a user
    ///
    /// - Parameters:
    ///   - email: String of user email
    ///   - password: String of user password
    ///   - completion: Returns upon completion of sign in
    func loginUser(email:String, password:String, completion:CreateUserCompletion?){
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil{
                //Some error occurred while trying to sign in user
                //handle error
                self.handleFirebaseError(error: (error as NSError?)!, completion: completion)
            }else{
                //No errors
                completion?(nil, user)
            }
        }
    }
    
    fileprivate func saveFBUserInfoInUserDefault(picture:String?, emailHash:String){
        self.userCredDict = [:]
        self.userCredDict["email"] = nil
        self.userCredDict["password"] = nil
        self.userCredDict["photoURL"] = picture
        self.userCredDict["emailHash"] = emailHash
        self.userCredDict["currentDevice"] = AppDelegate.DEVICEID
        self.userDefault.setValue(self.userCredDict, forKey: self.loginCredentials)
        return
    }
    
    ///Add noShow to delivery reference
    func addNoShow(id:String, call: Bool){
        userRef.child(emailHash).child("givenJob/\(id)").updateChildValues(["noShow":true, "called": call])
    }

    /// Gets a job object from firebase
    ///
    /// - Parameters:
    ///   - id: the ID of the job
    ///   - completion: A job object if successful, nil otherwise
    func getJobFromFirebase(id: String, completion: @escaping(Job?) -> ()){
        jobsRef.child(id).observeSingleEvent(of: .value) { (snap) in
            completion(Job(snapshot: snap, type: "delivery"))
        }
    }
    
    ///Puts the collection of jobs back in AllJobs reference if this user does not accept within 30 seconds
    func putBackJobs(){
        self.userRef.child(emailHash).child("givenJob").observe(.childAdded) { (snapshot) in
            let values = snapshot.value as? [String:Any]
            let state = values!["state"] as? String
            if (state == "delivery") || (state == nil){
                self.jobsRef.updateChildValues([snapshot.key:values as Any])
                self.userRef.child(self.emailHash).child("givenJob/\(snapshot.key)").removeValue()
            }
        }
        
    }
    
    /// Checks the incomplete jobs you may have
    ///
    /// - Parameter completion: True if incomplete, false otherwise
    func checkIncompleteJobs(completion: @escaping (Bool)->()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if snapshot.key == "givenJob"{
                    if let jobID = snapshot.value as? [String: AnyObject]{
                        completion(true)
                    }
                }
                
            }else{
                completion(false)
            }
        }
    }
    
    /// Returns the unfinished jobs as Job objects
    ///
    /// - Parameters:
    ///   - myLocation: Your current location
    ///   - completion: A job jobect if successful, nil otherwise
    func getUnfinishedJobs(myLocation: CLLocationCoordinate2D, completion: @escaping (Job?)->()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                if snapshot.key == "givenJob"{
                    if let jobID = snapshot.value as? [String: AnyObject]{
                        
                        let j = Job(snapshot: snapshot, type: "delivery")
                        j?.locList.insert(myLocation, at: 0)
                        completion(j)
                    }
                }
                
            }else{
                completion(nil)
            }
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func userCancelledJob(completion: @escaping ()->()){
        self.userRef.child(emailHash).updateChildValues(["flagged":true])
        // remove state, istaken to false,
        self.userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            guard let jobs = snapshot.value as? [String:Any] else{
                print("Couldn't find jobs to cancel")
                return
            }
            for (deliveryID, values) in jobs{
                guard var value = values as? [String:Any] else{
                    print("This error is inside userCancelledJobs")
                    return
                }
                if let state = value["state"] as? String{
                    if (state == "pickup"){
                        continue
                    }
                }
                
                value["state"] = nil
                value["isTaken"] = false
                value["jobTaker"] = nil
                guard let storeId = value["storeID"] as? String else {
                    print("Couldn't get storeID")
                    return
                }
                //next two line: remove the whole job from store and readd it as new
                self.storesRef.child("\(storeId)/deliveries/\(deliveryID)").removeValue()
                self.storesRef.child("\(storeId)/deliveries/\(deliveryID)").updateChildValues(value)
                //next two line: remove the whole job from alljobsref and readd it as new
                self.jobsRef.child(deliveryID).removeValue()
                self.jobsRef.child(deliveryID).updateChildValues(value)
                self.userRef.child(self.emailHash).child("givenJob/\(deliveryID)").removeValue()
                
            }//end of for loop
            completion()
        }
    }
    
    /**
     Add a job to Firebase Database
     */
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - deliveryLocation: <#deliveryLocation description#>
    ///   - pickupLocation: <#pickupLocation description#>
    ///   - recieverName: <#recieverName description#>
    ///   - recieverNumber: <#recieverNumber description#>
    ///   - pickupMainInstruction: <#pickupMainInstruction description#>
    ///   - pickupSubInstruction: <#pickupSubInstruction description#>
    ///   - deliveryMainInstruction: <#deliveryMainInstruction description#>
    ///   - deliverySubInstruction: <#deliverySubInstruction description#>
    ///   - pickupNumber: <#pickupNumber description#>
    func addTestJob(deliveryLocation: CLLocationCoordinate2D, pickupLocation: CLLocationCoordinate2D, recieverName: String, recieverNumber: String, pickupMainInstruction: String, pickupSubInstruction: String, deliveryMainInstruction: String, deliverySubInstruction: String, pickupNumber: String){
        
        let newJobID = self.jobsRef.childByAutoId().key
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        _ = "\(day)-\(month)-\(year) \(hour):\(minute):\(second)"
        
        
        let dict: [String: Any] = ["deliveryLat": deliveryLocation.latitude, "deliveryLong": deliveryLocation.longitude, "originLat": pickupLocation.latitude, "originLong": pickupLocation.longitude, "recieverName": recieverName,  "recieverNumber": recieverNumber,"pickupMainInstruction": pickupMainInstruction, "pickupSubInstruction": pickupSubInstruction, "deliveryMainInstruction": deliveryMainInstruction, "deliverySubInstruction": deliverySubInstruction, "storeName":"Walmart", "pickupNumber": pickupNumber]

        
        self.jobsRef.child(newJobID).updateChildValues(dict)

    }
    
    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func GetUserHashWhoAccepted(completion: @escaping(String) -> ()){
        userRef.child(emailHash).observeSingleEvent(of: .value) { (hash) in
            if let acceptedHash = hash.value as? [String: AnyObject]{
                print(acceptedHash)
                completion((acceptedHash["latestPostAccepted"] as? String)!)
            }
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func getCurrentUserInfo(completion: @escaping(BlipUser) -> ()){
        userRef.child(emailHash).observeSingleEvent(of: .value, with: { (userSnap) in
            if let user = BlipUser(snapFromUser: userSnap){
                completion(user)
            }
            else{
                print(userSnap, "Couldnt get current user info")
            }
        })
    }
    
    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func getAccountID(completion: @escaping (String) -> ()){
        userRef.observe(.value, with: { (snapshot) in
            let userDict = snapshot.value as! [String: AnyObject]
            let account = userDict[self.emailHash]!["account_ID"]! as! String
            completion(account)
        })
    }
    
    /// <#Description#>
    ///
    /// - Parameter completion: <#completion description#>
    func getCustomerID(completion: @escaping (String) -> ()){
        userRef.observe(.value, with: { (snapshot) in
            let userDict = snapshot.value as! [String: AnyObject]
            let customer = userDict[self.emailHash]!["customer_id"]! as! String
            completion(customer)
        })
    }
 
    func updateJobAccepterLocation(location: CLLocationCoordinate2D){
        userRef.child(self.emailHash).updateChildValues(["currentLatitude": location.latitude, "currentLongitude": location.longitude])
        
    }
    
    /*
     Handles all Firebase Errors
     */
    func handleFirebaseError(error: NSError, completion: CreateUserCompletion?){
        if let errorCode = StorageErrorCode(rawValue: error.code){
            switch (errorCode){
            case .downloadSizeExceeded:
                completion?("File is too large",nil)
                break
            case .unauthenticated:
                completion?("You are not authenticated",nil)
                break
            default:
                completion?("There is a problem storing image", nil)
            }
        }
        
        if let errorCode = AuthErrorCode(rawValue: error.code){
            switch (errorCode){
            case .invalidEmail:
                completion?("Invalid Email", nil)
                break
            case .emailAlreadyInUse:
                completion?("Email Already In Use", nil)
                break
            case .operationNotAllowed:
                completion?("Accounts Are Not Enabled: Enable In Console", nil)
                break
            case .userDisabled:
                completion?("Account Has Been Disabled", nil)
                break
            case .wrongPassword:
                completion?("Incorrect Password", nil)
                break
            case .weakPassword:
                completion?("Password is weak", nil)
                break
            case .userNotFound:
                completion?("User does not exist", nil)
                break
            default:
                completion?("There Was An Issue Authenticating, Try Again", nil)
            }
        }
    }
    
    
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
