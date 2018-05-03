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

typealias CreateUserCompletion = (_ errorMsg: String?, _ data: AnyObject?) ->Void

class ServiceCalls{
    
    private static let _instance = ServiceCalls()
    
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
    var availableJobs: [Job] = []
    let helper = HelperFunctions()
    
    var jobsRefHandle:DatabaseHandle!
    var userRefHandle: DatabaseHandle!
    var childHandle: DatabaseHandle!
    var currentBlipUser: BlipUser?
    
    init() {
        if let currentUser = Auth.auth().currentUser{
            self.emailHash = MD5(string: (currentUser.email)!)
        }
        //Trying to create a BlipUser Object to access user values
//        userRef.child(emailHash).observeSingleEvent(of: .value) { (snap) in
//            self.currentBlipUser = BlipUser(snapshot: snap)
//        }
    }
    
    //Checks if user is flagged
    func checkUserFlagged(completion: @escaping (Bool)->()){
        self.userRef.child(emailHash).child("flagged").observeSingleEvent(of: .value) { (snap) in
            if snap.exists(){
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    ///Finds jobs based on this user's location
    func findJob(myLocation: CLLocationCoordinate2D, userHash: String, completion: @escaping(Job?) -> ()){
        self.userRefHandle = userRef.child(emailHash).observe(.childAdded, with: { (snap) in
            
            if snap.key == "givenJob"{
                if let jobID = snap.value as? [String: AnyObject]{
                    let j = Job(snapshot: snap.childSnapshot(forPath: jobID.keys.first!), type: "delivery")
                    j?.locList.insert(myLocation, at: 0)
                    completion(j)
                }
            }
        })
//        userRef.child(emailHash).observe(.childAdded) { (snap) in
//            if snap.key == "givenJob"{
//                if let jobID = snap.value as? [String: AnyObject]{
//                    let j = Job(snapshot: snap.childSnapshot(forPath: jobID.keys.first!), type: "delivery")
//                    j?.locList.insert(myLocation, at: 0)
//                    completion(j)
//                }
//            }
//        }
        MyAPIClient.sharedClient.getBestJobAt(location: myLocation, userHash: userHash) { (error) in
            if error != nil{
                print(error!)
            }
        }
    }
    
    ///REMOVE MORE AS YOU ADD MORE OBSERVERS
    func removeFirebaseObservers(){
        userRef.child(emailHash).removeAllObservers()
        print("Observers Removed")
    }
    
    func completeJob(completion: @escaping() -> ()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            let deliveries = snapshot.value as? [String: AnyObject]
            self.userRef.child(self.emailHash).updateChildValues(["completedDeliveries": deliveries])
            self.userRef.child(self.emailHash).child("givenJob").removeValue()
            completion()
        }
    }
    
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
    func createUser(email: String, password:String, image:UIImage?, completion: CreateUserCompletion?){
        if image == nil{// imageview has no image
            let error = NSError()
            self.handleFirebaseError(error: error, completion: completion)
            return
        }
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil{
                //Handling Firebase Errors
                self.handleFirebaseError(error: (error as NSError?)!, completion: completion)
                return
            }
            //No errors
            //Do whatever is needed
            self.emailHash = self.MD5(string: (user?.email)!)
            //Send Email verification
            user?.sendEmailVerification(completion: { (error) in
                if error != nil{
                    print(error!.localizedDescription)
                    return
                }
                completion?(nil, user)
            })
        })
    }
    
    ///Add the new user's info into Database
    func addUserToDatabase(uid:String, name:String, email:String){
        let dict:[String:Any] = ["uid":uid ,"name":name ,"email":email ,"rating":5.0 ,"customer_id":"" ,"currentDevice":AppDelegate.DEVICEID]
        userRef.child(self.emailHash).updateChildValues(dict)
    }
    
    func uploadProfileImage(image:UIImage, completion: CreateUserCompletion?){
        let storageRef = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/").child("profile_image").child(emailHash)
        if let imageData = UIImageJPEGRepresentation(image, 0.1){
            storageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    completion?("error: Couldn't store image",nil)
                    return
                }
//                let profileImgURL = metadata?.downloadURL()?.absoluteString
                metadata?.storageReference?.downloadURL(completion: { (profileImgURL, error) in
                    if error != nil{
                        completion?("error: Couldn't store image",nil)
                        return
                    }
                    let profile = Auth.auth().currentUser?.createProfileChangeRequest()
                    profile?.photoURL = profileImgURL
                    profile?.commitChanges(completion: { (err) in
                        if err != nil{
                            completion?(err?.localizedDescription, nil)
                            return
                        }
                        let imgValues:[String:Any] = ["photoURL":profileImgURL!]
                        self.userRef.child(self.emailHash).updateChildValues(imgValues)
                        completion?(nil, nil)
                    })
                })
            })
            
        }
    }
    
    func updateCurrentDeviceToken(){
        let token = ["currentDevice": AppDelegate.DEVICEID]
        userRef.child(emailHash).updateChildValues(token)
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
    
    ///Add noShow to delivery reference
    func addNoShow(id:String, call: Bool){
        userRef.child(emailHash).child("givenJob/deliveries/\(id)").updateChildValues(["noShow":true, "called": call])
    }
    
    
    ///**
    //     doesn't load tasks that are taken
    // */
    //
//    func getJobsFromFirebase(MapView:MGLMapView , completion: @escaping ([String:BlipAnnotation]?)->()){
//        var annotationDict: [String:BlipAnnotation] = [:]
//        jobsRefHandle = jobsRef.observe(.childAdded, with: { (snap) in
//            if let job = Job(snapshot: snap){
//                let point = BlipAnnotation(coordinate: job.pickupLocationCoordinates, title: "Pickup", subtitle: job.jobID)
//                point.job = job
//                point.reuseIdentifier = "customAnnotation\(job.jobID)"
//                point.image = UIImage(icon: .icofont(.vehicleDeliveryVan), size: CGSize(width: 50, height: 50))
//                MapView.addAnnotation(point)
//                annotationDict[(job.jobID)!] = point
//                print(annotationDict)
//                completion(annotationDict)
//            }
//        })
//    }

    func getJobFromFirebase(id: String, completion: @escaping(Job?) -> ()){
        jobsRef.child(id).observeSingleEvent(of: .value) { (snap) in
            completion(Job(snapshot: snap, type: "delivery"))
        }
    }
    
    ///Puts the collection of jobs back in AllJobs reference if this user does not accept within 30 seconds
    func putBackJobs(){
        self.userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .childRemoved) { (snapshot) in
            if snapshot.key == "deliveries"{
                self.jobsRef.updateChildValues(snapshot.value as! [String:Any])
            }
        }
        self.userRef.child(emailHash).child("givenJob/deliveries").removeValue()
    }
    
    func userCancelledJob(){
        self.userRef.child(emailHash).updateChildValues(["flagged":true])
        self.putBackJobs()
    }
    
    /**
     Add a job to Firebase Database
     */
    
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
    
    func GetUserHashWhoAccepted(completion: @escaping(String) -> ()){
        userRef.child(emailHash).observeSingleEvent(of: .value) { (hash) in
            if let acceptedHash = hash.value as? [String: AnyObject]{
                print(acceptedHash)
                completion((acceptedHash["latestPostAccepted"] as? String)!)
            }
        }
    }

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

    func updateJobAccepterLocation(location: CLLocationCoordinate2D){
        userRef.child(self.emailHash).updateChildValues(["currentLatitude": location.latitude, "currentLongitude": location.longitude])
        
    }
    //
    //    func getLiveLocationOnce(hash: String, completion: @escaping (CLLocationCoordinate2D) -> ()){
    //
    //        userRef.child(hash).observeSingleEvent(of: .value) { (userSnap) in
    //            print("entered get live locations")
    //            let value = userSnap.value as? [String: AnyObject]
    //            let lat = value!["currentLatitude"] as? Double
    //            let long = value!["currentLongitude"] as? Double
    //            completion(CLLocationCoordinate2D(latitude: lat!, longitude: long!))
    //        }
    //    }
    //
    //    func getLiveLocation(hash: String, completion: @escaping (CLLocationCoordinate2D) -> ()){
    //
    //        userRefHandle = userRef.child(hash).observe(.value, with: { (userSnap) in
    //            print("entered get live locations")
    //            let value = userSnap.value as? [String: AnyObject]
    //            let lat = value!["currentLatitude"] as? Double
    //            let long = value!["currentLongitude"] as? Double
    //            completion(CLLocationCoordinate2D(latitude: lat!, longitude: long!))
    //        })
    //    }
    //
    //    func setRatingAndReview(rating: Double, review: String, hash: String){
    //
    //        userRef.child(hash).child("ratingSum").observeSingleEvent(of: .value) { (ratingsum) in
    //
    //            if let totalRating = ratingsum.value as? Double{
    //
    //                var x = totalRating
    //                x += rating
    //                self.userRef.child(hash).updateChildValues(["ratingSum": x])
    //                self.userRef.child(hash).child("reviews").updateChildValues([review: rating])
    //            }
    //        }
    //    }
    //
    //    func getJobPostedByCurrentUser(completion: @escaping(Job) -> ()){
    //
    //        userRef.child(emailHash).observeSingleEvent(of: .value) { (user) in
    //
    //            let lastPostSnapshot = user.childSnapshot(forPath: "lastPost")
    //            if let lastPost = lastPostSnapshot.value as? String{
    //                self.jobsRef.child(lastPost).observeSingleEvent(of: .value) { (snapshot) in
    //                    if let job = Job(snapshot: snapshot){
    //                        completion(job)
    //                    }
    //                    else{
    //                        print("Could not find job")
    //                    }
    //                }
    //            }
    //        }
    //    }
    //
    //    func checkIfAccepterReady(completion: @escaping(Int) -> ()){
    //
    //        getJobPostedByCurrentUser { (job) in
    //
    //            self.jobsRef.child(job.jobID).observeSingleEvent(of: .value, with: { (snapshot) in
    //                let job = Job(snapshot: snapshot)
    //
    //                if (snapshot.hasChild("isAccepterReady")){
    //                    completion(1) // Code 1 means that the accepter is ready
    //                }
    //                else{
    //                    completion(2) // Accepter isnt ready
    //                }
    //            })
    //        }
    //    }
    
    
    /*
     Handles all Firebase Errors
     */
    func handleFirebaseError(error: NSError, completion: CreateUserCompletion?){
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
