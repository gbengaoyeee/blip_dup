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
    
    ///Checks if user has been flagged for leaving a job
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
    
    ///Finds job(s) based on this user's location
    func findJob(myLocation: CLLocationCoordinate2D, userHash: String, completion: @escaping(Int?, Job?) -> ()){
        self.userRefHandle = userRef.child(emailHash).observe(.childAdded, with: { (snap) in
            if snap.key == "givenJob"{
                print("CHILD ADDED GOT TRIGGERD")
                if let jobID = snap.value as? [String: AnyObject]{
                    let j = Job(snapshot: snap, type: "delivery")
                    j?.locList.insert(myLocation, at: 0)
                    completion(nil, j)
                    self.userRef.removeAllObservers()
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
            
//            if let err = error as? AFError{
//                if (err.responseCode! == 400 || self.provider == "facebook.com")
//                {
//                    self.removeFirebaseObservers()
//                    completion(400, nil)//Not verified
//                    return
//                }
//                else if(err.responseCode! == 400 || !(Auth.auth().currentUser?.isEmailVerified)!){
//                    self.removeFirebaseObservers()
//                    completion(400, nil)//Not verified
//                    return
//                }
//                else if err.responseCode! == 500{
//                    self.removeFirebaseObservers()
//                    completion(500, nil)//Flagged
//
//                    return
//                }else{
//                    print("Here")
//                    self.removeFirebaseObservers()
//                    completion(404, nil)// No job Found
//                    return
//                }
//            }
        }
    }
    
    ///REMOVE MORE AS YOU ADD MORE OBSERVERS
    func removeFirebaseObservers(){
        userRef.child(emailHash).removeAllObservers()
        self.userRef.child(emailHash).child("givenJobs").removeAllObservers()
        print("Observers Removed")
    }
    
    
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
    
    func completedJob(deliveryID:String, storeID:String, type:String){
        if type == "Pickup"{
            let ref = Database.database().reference(withPath: "/Couriers/\(self.emailHash!)/givenJob/\(deliveryID)")
            let storeRef = Database.database().reference(withPath: "/stores/\(storeID)/deliveries/\(deliveryID)")
            ref.updateChildValues(["state":"pickup"])
            storeRef.updateChildValues(["state":"pickup"])
            return
        }
        userRef.child(emailHash).child("givenJob").child(deliveryID).observeSingleEvent(of: .value) { (snapshot) in
            guard var values = snapshot.value as? [String:Any] else{
                print("Couldn't get values")
                return
            }
            
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
    
    func setIsTakenOnGivenJobsAndStore(waypointList:[BlipWaypoint]){
        let ref = Database.database().reference(withPath: "Couriers/\(self.emailHash!)/givenJob")
        let storesRef = Database.database().reference(withPath: "stores")
        for way in waypointList{
            print("CHILDADDED WILL GET TRIGGERED")
            ref.child(way.delivery.identifier).updateChildValues(["isTaken":true, "jobTaker":self.emailHash!])
            storesRef.child("\(way.delivery.store.storeID)/deliveries/\(way.delivery.identifier!)").updateChildValues(["isTaken":true, "jobTaker":self.emailHash!])
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
    
    
    ///upload profile image to firebase storage
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
    
    ///Get facebook user data
//    func getFBUserData(completion: @escaping (String?,String?,String?)->()){
//        if((FBSDKAccessToken.current()) != nil){
//            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
//                if (error == nil){
//                    //everything works
//                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
//                    Auth.auth().signIn(with: credential) { (user, error) in
//                        if error != nil {
//                            print(error as Any)
//                            return
//                        }
//                        print("Signed in with Facebook")
//                        let data = result as! [String: AnyObject]
//                        let FBid = data["id"] as? String
//                        let firstName:String = data["first_name"] as! String
//                        let lastName:String = data["last_name"] as! String
//                        let email:String = data["email"] as! String
//
//                        let url = URL(string: "https://graph.facebook.com/\(FBid!)/picture?type=large&return_ssl_resources=1")
//                        let profile = user?.createProfileChangeRequest()
//                        profile?.photoURL = url
//                        profile?.commitChanges(completion: { (err) in
//                            if err != nil{
//                                print(err?.localizedDescription ?? "")
//                            }else{
//                                let emailHash = self.MD5(string: (user?.email)!)
//                                self.dbRef.child("Couriers").child(emailHash).child("photoURL").setValue(url?.absoluteString)
//                                self.emailHash = emailHash //MIGHT WANT TO REMOVE THIS LATER ON
//                                self.addUserToDatabase(uid: (user?.uid)!, firstName: firstName, lastName: lastName, email: (user?.email)!, provider: "facebook")
//                                self.saveFBUserInfoInUserDefault(picture: url?.absoluteString, emailHash: emailHash)
//                                //Add completion
//                                completion(email,firstName,lastName)
//                            }
//                        })
//                    }
//                }
//                else{
//                    print(error?.localizedDescription ?? "")
//                    return
//                }
//            })
//        }
//    }
    
    
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
        self.userRef.child(emailHash).child("givenJob").observe(.childAdded) { (snapshot) in
            let values = snapshot.value as? [String:Any]
            let state = values!["state"] as? String
            if (state == "delivery") || (state == nil){
                self.jobsRef.updateChildValues([snapshot.key:values as Any])
                self.userRef.child(self.emailHash).child("givenJob/\(snapshot.key)").removeValue()
            }
        }
        
    }
    
    
    func checkIncompleteJobs(completion: @escaping (Bool)->()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                print(snapshot)
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
    
    func getUnfinishedJobs(myLocation: CLLocationCoordinate2D, completion: @escaping (Job?)->()){
        userRef.child(emailHash).child("givenJob").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(){
                print(snapshot)
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
    
    //    func getUserInfo(hash: String, completion: @escaping (BlipUser?) -> ()){
    //        print("user", Auth.auth().currentUser)
    //        print("email", (Auth.auth().currentUser?.email)!)
    //        print("hash", emailHash)
    //        userRef.child(hash).observeSingleEvent(of: .value) { (userSnap) in
    //
    //            if let user = BlipUser(snapshot: userSnap){
    //
    //                if userSnap.hasChild("reviews"){
    //
    //                    let dataDict = userSnap.value as? [String: AnyObject]
    //
    //                    user.reviews = dataDict!["reviews"] as? [String: Double]
    //                }
    //
    //                completion(user)
    //            }
    //            else{
    //                print(userSnap, "couldnt get user info from snapshot")
    //            }
    //        }
    //    }
    //
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
    //
    //    func getJobAcceptedByCurrentUser(completion: @escaping(Job?) -> ()){
    //
    //        userRef.child(emailHash).observeSingleEvent(of: .value) { (user) in
    //
    //            let acceptedSnapshot = user.childSnapshot(forPath: "didAccept")
    //            if let acceptedPost = acceptedSnapshot.value as? String{
    //                self.jobsRef.child(acceptedPost).observeSingleEvent(of: .value) { (snapshot) in
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
    //
    ////    func removedJobFromFirebase(completion: @escaping (Job?)->()){
    ////
    ////        jobsRefHandle = jobsRef.observe(.childRemoved, with: { (snapshot) in
    ////            let job = Job(snapshot: snapshot)
    ////            completion(job)
    ////        })
    ////
    ////    }
    //
//    func getChargeIDFor(job: Job, completion: @escaping(String) ->()){
//        
//        jobsRef.child(job.jobID).child("charge").observeSingleEvent(of: .value) { (id) in
//            if let charge = id.value as? String{
//                completion(charge)
//            }
//        }
//    }
    //
    ////    func removeAcceptedJobsFromMap(completion: @escaping (Job?)->()){
    ////
    ////        jobsRefHandle = jobsRef.observe(.childChanged, with: { (snapshot) in
    ////            let job = Job(snapshot: snapshot)
    ////            // if the task is accepted but not completed put the job in completion to be removed when called
    ////            if (snapshot.hasChild("isTakenBy") && job?.jobOwnerEmailHash != self.emailHash){
    ////                print("Removed Accepted Job From Map")
    ////                completion(job)
    ////            }
    ////        })
    ////    }

    //    func cancelJobPost(job: Job){
    //
    //        jobsRef.child(job.jobID).removeValue()
    //    }
    //
    //    func startJobPressedByAccepter(job: Job, completion: @escaping(String) -> ()){
    //
    //        jobsRef.child(job.jobID).updateChildValues(["accepterHasBegun": true, "jobHasBegun": false])
    //    }
    //
    ////    func updateUI(map: MGLMapView, completion: @escaping(Int?, Job?, [String:BlipAnnotation]?) -> ()){
    ////
    ////        jobsRef.observe(.childAdded) { (addedJob) in
    ////
    ////            let job = Job(snapshot: addedJob)
    ////
    ////            if job?.jobOwnerEmailHash != self.emailHash{
    ////
    ////                print("making annotation")
    ////                var annotationDict: [String:BlipAnnotation] = [:]
    ////                let jobPosterRef = self.userRef.child((job?.jobOwnerEmailHash)!)
    ////                jobPosterRef.observeSingleEvent(of: .value, with: { (snapshot2) in
    ////                    let userVal = snapshot2.value as? [String:AnyObject]
    ////                    job?.jobOwnerRating = userVal!["Rating"] as? Float
    ////                    job?.jobOwnerPhotoURL = URL(string: (userVal!["photoURL"] as? String)!)
    ////                    let point = BlipAnnotation()
    ////                    point.job = job
    ////                    point.coordinate = (job?.location.coordinate)!
    ////                    point.title = job?.title
    ////                    point.subtitle = ("$"+"\((job?.wage_per_hour)!)"+"/Hour")
    ////                    point.photoURL = job?.jobOwnerPhotoURL
    ////                    map.addAnnotation(point)
    ////                    annotationDict[(job?.jobID)!] = point
    ////                    print("Added annotation")
    ////                    completion(0, nil, annotationDict)
    ////                })
    ////            }
    ////        }
    ////
    ////        var userValues: [String: Any] = ["Initialized key": "Initialized value"]
    ////
    ////        userRef.child(emailHash).observe(.childAdded) { (userData) in
    ////
    ////            userValues[userData.key] = userData.value
    ////            print("child Added to userref", userData.key)
    ////
    ////            userData.ref.observe(.childAdded, with: { (jobID) in
    ////
    ////                print(jobID.key)
    ////                jobID.ref.observe(.childAdded, with: { (jobData) in
    ////
    ////                    print(jobData.key)
    ////
    ////                    if userValues["acceptedJob"] != nil{
    ////
    ////                        print(jobData.key)
    ////                        if (jobData.key == "completed"){
    ////                            print(7)
    ////                            completion(7, nil, nil) // current user completed a post
    ////                        }
    ////
    ////                        else if (jobData.key == "completedByTaker"){
    ////                            print(11)
    ////                            completion(11, nil, nil) // current user completed a post
    ////                        }
    ////
    ////                        else if (jobData.key == "hasStarted"){
    ////                            print(8)
    ////                            completion(8, nil, nil) // Job hasStarted and current user is accepter
    ////                        }
    ////
    ////                        else if (jobData.key == "isAccepterReady"){
    ////                            print(9)
    ////                            completion(9, nil, nil) // Current users post has been accepted and the accepter is ready
    ////                        }
    ////
    ////                        else if (jobData.key == "isTakenBy"){
    ////                            print(10)
    ////                            completion(10, nil, nil) // Current users post got accepted
    ////                        }
    ////                    }
    ////
    ////                    else if userValues["lastPostAccepted"] != nil{
    ////
    ////                        print(jobData.key)
    ////                        if (jobData.key == "completed"){
    ////
    ////                            completion(5, nil, nil) // Current users post was completed
    ////                        }
    ////
    ////                        else if (jobData.key == "hasStarted"){
    ////
    ////                            completion(1, nil, nil) // Code 1 implies that the job has started for poster
    ////
    ////                        }
    ////
    ////                        else if (jobData.key == "isAccepterReady"){
    ////
    ////                            completion(4, nil, nil) // Current users post has been accepted and the accepter is ready
    ////                        }
    ////
    ////                        else if (jobData.key == "isTakenBy"){
    ////
    ////                            completion(3, nil, nil) // Current users post got accepted
    ////                        }
    ////                    }
    ////                })
    ////            })
    ////        }
    ////    }
    //
    //
    ///**
    //    When you accept a job, a device token is stored for notification.
    //
    //     - parameter job: The job being accepted.
    //     - parameter user: The user who accepted the job.
    //     - parameter completion: The completion block where device token is stored.
    //     - returns: Void
    //*/
    //    func acceptPressed(job: Job, user: User, completion: @escaping (String)->()){
    //
    //        let userAcceptedRef = self.userRef.child(self.emailHash).child("acceptedJob")
    //        let jobPosterRef = self.userRef.child(job.jobOwnerEmailHash).child("lastPostAccepted")
    //
    //        let jobDict: [String:Any] = ["latitude":job.latitude, "longitude":job.longitude, "jobOwner":job.jobOwnerEmailHash, "jobTitle":job.title, "jobDescription":job.description, "price":"\(job.wage_per_hour)", "time":"\(job.maxTime)", "fullName":(job.jobOwnerFullName)!, "isTakenBy": self.emailHash]
    //
    //        // add the accepted job values to both owner and accepter reference for easier observation
    //        userAcceptedRef.child(job.jobID).updateChildValues(jobDict)
    //        jobPosterRef.child(job.jobID).updateChildValues(jobDict)
    //
    //        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
    //            let userValues = snapshot.value as! [String : AnyObject]
    //
    //            //add to the "uAccepted" ref for current user
    //            guard let deviceToken = userValues[job.jobOwnerEmailHash]!["currentDevice"]! as? String else{return}
    //
    //            //remove the accepted job from AllJobs reference
    //            self.jobsRef.child(job.jobID).removeValue()
    //            completion(deviceToken)
    //        })
    //    }
    //
    //    //start job pressed by accepter
    //    func accepterReady(job:Job, completion: @escaping (String?)->()){
    //
    //        // Update both users "acceptedJob" and "lastPostedAccepted"
    //        let accepterReady_JobRef = self.userRef.child(self.emailHash).child("acceptedJob").child(job.jobID)
    //        let jobOwnerLastPostJobRef = self.userRef.child(job.jobOwnerEmailHash).child("lastPostAccepted").child(job.jobID)
    //        jobOwnerLastPostJobRef.updateChildValues(["isAccepterReady": true])
    //        accepterReady_JobRef.updateChildValues(["isAccepterReady": true])
    //
    //        //        jobsRef.child(job.jobID).updateChildValues(["isAccepterReady":true])
    //        userRef.child(job.jobOwnerEmailHash).observeSingleEvent(of: .value) { (snapshot) in
    //            if let user = snapshot.value as? [String: AnyObject]{
    //                let currentDevice = user["currentDevice"] as? String
    //                completion(currentDevice)
    //            }
    //        }
    //    }
    //
    //    //start job pressed by poster
    //    func ownerReady(job:Job, completion: @escaping (String?)->()){
    //        //        jobsRef.child(job.jobID).updateChildValues(["hasStarted":true])
    //        let accepterReady_JobRef = self.userRef.child(self.emailHash).child("acceptedJob").child(job.jobID)
    //        let jobOwnerLastPostJobRef = self.userRef.child(job.jobOwnerEmailHash).child("lastPostAccepted").child(job.jobID)
    //        accepterReady_JobRef.updateChildValues(["hasStarted":true])
    //        jobOwnerLastPostJobRef.updateChildValues(["hasStarted":true])
    //
    //        userRef.child(self.emailHash).child(job.jobID).observeSingleEvent(of: .value) { (snap) in
    //            if let jobValues = snap.value as? [String:AnyObject]{
    //                if let accepterHash = jobValues["isTakenBy"] as? String{
    //                    //Get the accepter deviceToken
    //                    self.userRef.child(accepterHash).observeSingleEvent(of: .value, with: { (snap2) in
    //                        if let userValues = snap2.value as? [String:AnyObject]{
    //                            guard let deviceToken = userValues["currentDevice"]! as? String else{return}
    //                            completion(deviceToken)
    //                        }
    //                    })//    End of snap2
    //                }
    //            }
    //        }
    //
    //    }
    //
    //    func endJobPressed(job: Job){
    //
    //        userRef.child(emailHash).child("acceptedJob").updateChildValues(["completedByTaker": true])
    //    }
    //
    //    func confirmedJobEnd(job: Job){
    //
    //        userRef.child(emailHash).child("lastPostAccepted").updateChildValues(["completed": true])
    //        userRef.child(emailHash).child("lastPostAccepted").observeSingleEvent(of: .value) { (snapshot) in
    //            if let jobDict = snapshot.value as? [String: AnyObject]{
    //                self.fireBaseRef.updateChildValues(["Completed Jobs": jobDict])
    //                if let taker = jobDict["isTakenBy"] as? String{
    //                    self.userRef.child(taker).child("acceptedJob").removeValue()
    //                }
    //            }
    //        }
    //    }
    //
    
    func getAccountID(completion: @escaping (String) -> ()){
        userRef.observe(.value, with: { (snapshot) in
            let userDict = snapshot.value as! [String: AnyObject]
            let account = userDict[self.emailHash]!["account_ID"]! as! String
            completion(account)
        })
    }
    
    func getCustomerID(completion: @escaping (String) -> ()){
        userRef.observe(.value, with: { (snapshot) in
            let userDict = snapshot.value as! [String: AnyObject]
            let customer = userDict[self.emailHash]!["customer_id"]! as! String
            completion(customer)
        })
    }
    //
    //    func checkJobAcceptedStatus(completion: @escaping (Int?, String?) -> ()){
    //
    //        userRef.child(emailHash).observe(.childAdded, with: { (userSnap) in
    //            let key = userSnap.key
    //            if key == "uAccepted"{// priority
    //                print("You accepted a job")
    //                completion(1, (userSnap.value as! String))// Means that current user accepted a job
    //            }
    //            else if key == "latestPostAccepted"{
    //                print("Your job got accepted")
    //                completion(2, (userSnap.value as! String))// Means that current user's job got accepted
    //            }else{
    //                print("Something else got added")
    //                completion(0, nil)// Means nothing happened
    //            }
    //
    //        })
    //    }
    //
    //
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
