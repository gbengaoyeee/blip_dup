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
    
    ///Finds jobs based on this user's location
    func findJob(myLocation: CLLocationCoordinate2D, userHash: String, completion: @escaping(Job?) -> ()){
        userRef.child(emailHash).observe(.childAdded) { (snap) in
            if snap.key == "givenJob"{
                if let jobID = snap.value as? [String: AnyObject]{
                    let j = Job(snapshot: snap.childSnapshot(forPath: jobID.keys.first!), type: "delivery")
                    j?.locList.insert(myLocation, at: 0)
                    completion(j)
                }
            }
        }
        MyAPIClient.sharedClient.getBestJobAt(location: myLocation, userHash: userHash) { (error) in
            if error != nil{
                print(error!)
            }
        }
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
    
    /**
     Add a job to Firebase Database
     */
    
    func addTestJob(deliveryLocation: CLLocationCoordinate2D, pickupLocation: CLLocationCoordinate2D, recieverName: String, recieverNumber: String, pickupMainInstruction: String, pickupSubInstruction: String, deliveryMainInstruction: String, deliverySubInstruction: String){
        
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
        
        
        var dict: [String: Any] = ["deliveryLat": deliveryLocation.latitude, "deliveryLong": deliveryLocation.longitude, "originLat": pickupLocation.latitude, "originLong": pickupLocation.longitude, "recieverName": recieverName,  "recieverNumber": recieverNumber,"pickupMainInstruction": pickupMainInstruction, "pickupSubInstruction": pickupSubInstruction, "deliveryMainInstruction": deliveryMainInstruction, "deliverySubInstruction": deliverySubInstruction, "storeName":"Walmart"]

        
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
