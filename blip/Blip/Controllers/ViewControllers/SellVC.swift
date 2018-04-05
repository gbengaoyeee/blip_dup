////
////  SellVC02.swift
////  Blip
////
////  Created by Gbenga Ayobami on 2017-07-19.
////  Copyright © 2017 Gbenga Ayobami. All rights reserved.
////
//
//import UIKit
//import Firebase
//import Lottie
//import CoreLocation
//import Material
//import FBSDKLoginKit
//import Mapbox
//import PopupDialog
//import Alamofire
//import Stripe
//import Kingfisher
//import NotificationBannerSwift
//import AZDialogView
//
//class SellVC: UIViewController,  MGLMapViewDelegate, CLLocationManagerDelegate, STPPaymentContextDelegate{
//
//    
//    @IBOutlet weak var rootView: UIView!
//    @IBOutlet weak var scheduleJob: TextField!
//    @IBOutlet weak var submitJobButton: RaisedButton!
//    @IBOutlet weak var jobDetailsView: UIView!
//    @IBOutlet weak var jobPriceView: UIView!
//    @IBOutlet weak var cancelPrice: RaisedButton!
//    @IBOutlet weak var cancelDetails: RaisedButton!
//    @IBOutlet weak var numberOfHoursTF: TextField!
//    @IBOutlet weak var pricePerHour: TextField!
//    @IBOutlet weak var jobPriceViewConstraint: NSLayoutConstraint!
//    @IBOutlet weak var jobDetailsTF: TextView!
//    @IBOutlet weak var jobTitleTF: TextField!
//    @IBOutlet weak var jobDetailsConstraint: NSLayoutConstraint!
//    @IBOutlet weak var postJobButton: RaisedButton!
//    @IBOutlet weak var MapView: MGLMapView!
//    fileprivate var viewJobButton: FlatButton!
//
//    var dbRef: DatabaseReference!
//    var acceptedJob: Job!
//    let service = ServiceCalls.instance
//    var locationManager = CLLocationManager()
//    let camera = MGLMapCamera()
//    var currentLocation: CLLocationCoordinate2D!
//    var paymentContext: STPPaymentContext? = nil
//    let backendBaseURL: String? = "https://us-central1-blip-c1e83.cloudfunctions.net/"
//    let stripePublishableKey = "pk_test_K45gbx2IXkVSg4pfmoq9SIa9"
//    let companyName = "Blip"
//    var locationTimer = Timer()
//    var latestAccepted:Job!
//    let loadingAnimation = LOTAnimationView(name: "loading")
//    var allAnnotations: [String:CustomMGLAnnotation]!
//    let check = LOTAnimationView(name: "check")
//    var connectivity = Connectivity()
//    var internet:Bool!
//    let userDefault = UserDefaults.standard
//    
//    /*---Firebase Handles---*/
//    var lastPostAcceptedInAppHandle: UInt!
//    var acceptedJobInAppHandle: UInt!
//    
//    ////////////////////////Functions associated with the controller go here//////////////////////////
//    
//    override func viewDidLoad() {
//        self.MapView.delegate = self
//        MapView.compassView.isHidden = true
//        self.navigationController?.navigationBar.isHidden = true
//        prepareCancelButtons()
//        self.hideKeyboardWhenTappedAround()
//        prepareTitleTextField()
//        preparePostJobButton()
//        useCurrentLocations()
//        prepareJobForm()
//        self.prepareBannerLeftView()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        //Try to do all viewDidAppear stuff in connectivityChanged() function
//        NotificationCenter.default.addObserver(self, selector: #selector(connectivityChanged), name: Notification.Name.reachabilityChanged, object: connectivity)
//        do{
//            try connectivity?.startNotifier()
//        }catch{
//            print("Could not start the notifier")
//        }
//
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.navigationController?.navigationBar.isHidden = false
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        self.navigationController?.navigationBar.isHidden = true
//    }
//    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        removeAvailableObservers()
//    }
//    
//    func saveUserInfoInUserDefault(){
//        service.getUserInfo(hash: service.emailHash) { (currUser) in
//            var dataDict:[String:AnyObject] = [:]
//            dataDict["name"] = currUser?.name as AnyObject
//            dataDict["rating"] = currUser?.rating as AnyObject
//            dataDict["photoUrl"] = currUser?.photoURL?.absoluteString as AnyObject
//            if let completedJobs = currUser?.completedJobs{
//                dataDict["num_completed_jobs"] = completedJobs.count as AnyObject
//            }
//            if let reviews = currUser?.reviews{
//                dataDict["reviews"] = reviews as AnyObject
//            }
//            self.userDefault.setValue(dataDict, forKey: "userProfileInfo")
//        }
//    }
//    
//    //Internet Notification for when internet is lost or came back
//    @objc func connectivityChanged(notification: Notification){
//        let connectivity = notification.object as! Connectivity
//        if (connectivity.connection == .wifi || connectivity.connection == .cellular){
//            self.internet = true
//            DispatchQueue.main.async {
//                self.view.isUserInteractionEnabled = true
//                self.observeLastEventBeforeTerminationInLastPostAccepted()
//                self.observeLastEventBeforeTerminationInAcceptedJob()
//                self.observeForNewEventsInLastPostAccepted()
//                self.observeForNewEventsInAcceptedJob()
//                self.prepareMap()   // Prepare map thing on the main thread if there is internet on first run
//                self.saveUserInfoInUserDefault()
//                
//                print("REGAINED CONNECTION")
//            }
//            
//        }else{
//            self.internet = false
//            DispatchQueue.main.async {
//                self.view.isUserInteractionEnabled = false
//                self.present(self.popupForNoInternet(), animated: true, completion: nil)
//            }
//            print("Connection Gone")
//        }
//    }
//    
///*
//    This function is for the job Owner and should be transfered(this function) to the other grocery app
//    It should only check for when the courier has arrived to drop off goods
//*/
//    func observeForNewEventsInLastPostAccepted(){
//        lastPostAcceptedInAppHandle = service.userRef.child(service.emailHash).child("lastPostAccepted").observe(.childChanged) { (snap) in
//            if let jobValues = snap.value as? [String:AnyObject]{
//                /*
//                 precondition: childchanged works for both added and removed and of course changed
//                 
//                    This is a bottom up algorithm. Because the events come in the same order, therefore it checks for the last relevant event that
//                    happened. For example when isAccepterReady is set,
//                    it will only call the third else if statement
//                 
//                 */
//                if jobValues["completed"] != nil{
//                    // goods has been delivered
//                    print("D")
//                }
//                else if jobValues["hasStarted"] != nil{
//                    //supposed to be for when owner is ready
//                    print("C")
//                }
//                else if jobValues["isAccepterReady"] != nil{
//                    print("B")
//                    //supposed to be for when accepter presses start
//                }
//                else if jobValues["isTakenBy"] != nil{
//                    //when someone accepts your job
//                    print("A")
//                }
//            }
//        }
//    }
//    
///*
//    This function is to get the last event that occured before the termination of the app
//    This function is only to be called once each time the app is opened after termination
//    Again this function is meant for the job poster/owner
//*/
//    func observeLastEventBeforeTerminationInLastPostAccepted(){
//        service.userRef.child(service.emailHash).child("lastPostAccepted").observeSingleEvent(of: .childAdded) { (snap) in
//            if let jobValues = snap.value as? [String:AnyObject]{
//                /*
//                 
//                 This is a bottom up algorithm. Because the events come in the same order, therefore it checks for the last relevant event that
//                 happened. For example when isAccepterReady is set,
//                 it will only call the third else if statement
//                 
//                 */
//                if jobValues["completed"] != nil{
//                    // goods has been delivered
//                    print("D")
//                }
//                else if jobValues["hasStarted"] != nil{
//                    //supposed to be for when owner is ready
//                    print("C")
//                }
//                else if jobValues["isAccepterReady"] != nil{
//                    print("B")
//                    //supposed to be for when accepter presses start
//                }
//                else if jobValues["isTakenBy"] != nil{
//                    //when someone accepts your job
//                    print("A")
//                }
//            }
//        }
//    }
//    
///*
//    This function is used to observe the most recent job this user accepted
//*/
//    func observeForNewEventsInAcceptedJob(){
//        acceptedJobInAppHandle = service.userRef.child(service.emailHash).child("acceptedJob").observe(.childChanged) { (snap) in
//            if let jobValues = snap.value as? [String:AnyObject]{
//                /*
//                 precondition: childchanged works for both added and removed and of course changed
//                 
//                 This is a bottom up algorithm. Because the events come in the same order, therefore it checks for the last relevant event that
//                 happened. For example when isAccepterReady is set,
//                 it will only call the third else if statement
//                 
//                 */
//                if jobValues["completed"] != nil{
//                    // goods has been delivered
//                    print("H")
//                }
//                else if jobValues["hasStarted"] != nil{
//                    //supposed to be for when owner is ready
//                    print("G")
//                }
//                else if jobValues["isAccepterReady"] != nil{
//                    print("F")
//                    //supposed to be for when accepter presses start
//                }
//                else if jobValues["isTakenBy"] != nil{
//                    //when this user accepts a job
//                    print("E")
//                }
//            }
//        }
//    }
//    
//    func observeLastEventBeforeTerminationInAcceptedJob(){
//        service.userRef.child(service.emailHash).child("acceptedJob").observeSingleEvent(of: .childAdded) { (snap) in
//            if let jobValues = snap.value as? [String:AnyObject]{
//                /*
//                 precondition: childchanged works for both added and removed and of course changed
//                 
//                 This is a bottom up algorithm. Because the events come in the same order, therefore it checks for the last relevant event that
//                 happened. For example when isAccepterReady is set,
//                 it will only call the third else if statement
//                 
//                 */
//                if jobValues["completed"] != nil{
//                    // goods has been delivered
//                    print("H")
//                }
//                else if jobValues["hasStarted"] != nil{
//                    //supposed to be for when owner is ready
//                    print("G")
//                }
//                else if jobValues["isAccepterReady"] != nil{
//                    print("F")
//                    //supposed to be for when accepter presses start
//                }
//                else if jobValues["isTakenBy"] != nil{
//                    //when this user accepts a job
//                    print("E")
//                }
//            }
//        }
//    }
//    
///*
//     removes all attached observers
//*/
//    func removeAvailableObservers(){
//           service.jobsRef.removeObserver(withHandle: service.jobsRefHandle)
//        service.userRef.child(service.emailHash).child("lastPostAccepted").removeAllObservers()
//            service.userRef.child(service.emailHash).child("acceptedJob").removeAllObservers()
//    }
//    
///*
//     
//*/
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        if segue.identifier == "startJobFromSellVC"{
//            if let dest = segue.destination as? StartJob{
//                dest.job = self.acceptedJob
//            }
//        }
//        
//        if segue.identifier == "endJobFromSellVC"{
//            
//            if let dest = segue.destination as? EndJob{
//                dest.job = self.acceptedJob
//            }
//        }
//        
//    }
//
//    //Sets the camera for the mapview and sets current location to users current locations
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
//        self.camera.centerCoordinate = locValue
//        self.camera.altitude = CLLocationDistance(11000)
//        self.camera.pitch = CGFloat(60)
//        self.MapView.setCenter(locValue, zoomLevel: 5, direction: 0, animated: false)
//        self.MapView.setZoomLevel(7, animated: true)
//        self.MapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
//        currentLocation = locValue
//        service.updateJobAccepterLocation(location: locValue)
//        manager.stopUpdatingLocation()
//    }
//
//    //When the postJob red button is pressed
//    @IBAction func postJobPressed(_ sender: Any) {
//    
//        self.postJobButton.isHidden = true
//        self.jobDetailsConstraint.constant = 77
//        UIView.animate(withDuration: 0.5, animations: {self.view.layoutIfNeeded()})
// 
//    }
//    
//    
//    
//    
//    //When next is pressed on the Job details form
//    @IBAction func nextPressedOnDetails(_ sender: Any) {
//        
//        if (!jobDetailsTF.isEmpty && !jobTitleTF.isEmpty ){
//            jobDetailsConstraint.constant = 800
//            UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
//            jobPriceViewConstraint.constant = 77
//            UIView.animate(withDuration: 2, animations: {self.view.layoutIfNeeded()})
//            
//        }
//    }
//    
//    //When submit is pressed after the job price form
//    @IBAction func submitJob(_ sender: Any) {
//        
//        if (CLLocationManager.locationServicesEnabled()){
//            if (pricePerHour.text == "" || numberOfHoursTF.text == "" || jobTitleTF.text == "" ||
//                jobDetailsTF.text == ""){
//                
//                print("Empty fields, please check again")
//                return
//            }
//                
//            else{   // add job things to firebase
//                
//                let popup = preparePopupForJobPosting(wage: pricePerHour.text!, time: numberOfHoursTF.text!)
//                self.present(popup, animated: true, completion: nil)
//                
//            }
//            
//        }
//        else{
//            let locationServicesPopup = PopupDialog(title: "Error", message: "Please enable location services to allow us to determine the location for your job")
//            self.present(locationServicesPopup, animated: true)
//            print("Location not enabled")
//            return
//        }
//        
//    }
//    
//    //When you cancel the details, the view is animated here
//    @IBAction func cancelDetailsPressed(_ sender: Any) {
//        self.resetTextFields()
//        jobDetailsConstraint.constant = 800
//        UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
//        postJobButton.isHidden = false
//    }
//    
//    //When you cancel price by pressing back, the view is animated here
//    @IBAction func cancelPricePressed(_ sender: Any) {
//
//        jobPriceViewConstraint.constant = 1600
//        UIView.animate(withDuration: 1.5, animations: {self.view.layoutIfNeeded()})
//        jobDetailsConstraint.constant = 77
//        UIView.animate(withDuration: 2, animations: {self.view.layoutIfNeeded()})
//        
//    }
//    
//    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
//
////        if let anno = annotation as? CustomMGLAnnotation{
////            let popup = self.prepareAndShowPopup(job: anno.job!)
////            self.present(popup, animated: true, completion: nil)
////        }
//
//    }
//
//    //Loads the profilePicture for the map annotation
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        // This example is only concerned with point annotations.
//        guard annotation is MGLPointAnnotation else {
//            return nil
//        }
//        let annotationView = CustomAnnotationView()
//        if let castedAnnotation = annotation as? CustomMGLAnnotation{
//
//            annotationView.frame = CGRect(x: 0, y: 0, width: 35, height: 35 )
//            let profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35 ))
//            profileImage.contentMode = .scaleAspectFill
//            profileImage.kf.setImage(with: castedAnnotation.photoURL)
//            profileImage.isUserInteractionEnabled = true
//            annotationView.addSubview(profileImage)
//            annotationView.cornerRadius = annotationView.frame.size.height/2
//            annotationView.isUserInteractionEnabled = true
//        }
//        return annotationView
//
//    }
//
//    
//    //Prepares custom textfields for the job form
//    func prepareTitleTextField(){
//        
//        self.pricePerHour.font = UIFont(name: "Century Gothic", size: 17)
//        self.pricePerHour.textColor = Color.white
//        self.pricePerHour.placeholderActiveColor = Color.white
//        self.pricePerHour.detailColor = Color.white
//        self.pricePerHour.placeholderNormalColor = Color.white
//        self.numberOfHoursTF.font = UIFont(name: "Century Gothic", size: 17)
//        self.numberOfHoursTF.textColor = Color.white
//        self.numberOfHoursTF.placeholderActiveColor = Color.white
//        self.numberOfHoursTF.detailColor = Color.white
//        self.numberOfHoursTF.placeholderNormalColor = Color.white
//        self.jobTitleTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
//        self.jobDetailsTF.placeholder = "Enter a job description; here is where you can be clear and concise with the full details of your job"
//        self.jobDetailsTF.placeholderColor = Color.white
//        self.jobDetailsTF.font = UIFont(name: "Century Gothic", size: 17)
//        self.jobDetailsTF.textColor = Color.white
//        self.jobTitleTF.font = UIFont(name: "Century Gothic", size: 17)
//        self.jobTitleTF.textColor = Color.white
//        self.jobTitleTF.placeholder = "Job Title"
//        self.jobTitleTF.placeholderActiveColor = Color.white
//        self.jobTitleTF.detailLabel.text = "A short title for your job"
//        self.jobTitleTF.detailColor = Color.white
//        self.jobTitleTF.placeholderNormalColor = Color.white
//        self.scheduleJob.font = UIFont(name: "Century Gothic", size: 17)
//        self.scheduleJob.textColor = Color.white
//        self.scheduleJob.placeholderActiveColor = Color.white
//        self.scheduleJob.detailColor = Color.white
//        self.scheduleJob.placeholderNormalColor = Color.white
//    }
//    
//    
//    //Prepares the post job button
//    func preparePostJobButton(){
//        postJobButton.image = Icon.cm.pen
//        postJobButton.cornerRadius = postJobButton.frame.height/2
//    }
//    
//    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
//        return true
//    }
//    
//    //Loads a rating animation using the users rating, and puts this when the map annotation is clicked
//    func mapView(_ mapView: MGLMapView, leftCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
//        
//        let animation = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 50))
//        let ratingAnimation = LOTAnimationView(name: "5_stars")
//        animation.handledAnimation(Animation: ratingAnimation)
//        var rating = CGFloat(0)
//        
//        if let anno = annotation as? CustomMGLAnnotation{
//            rating = CGFloat((anno.job?.orderer.rating)!/5)
//        }        
//        ratingAnimation.play(toProgress: rating, withCompletion: nil)
//        return animation
//    }
//    
///**
//    //Loads an animation
// */
//    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
//        let picture = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
//        picture.cornerRadius = picture.frame.height/2
//        
//        if let anno = annotation as? CustomMGLAnnotation{
//            if let profilePic = anno.job?.orderer.photoURL{
//                picture.contentMode = .scaleAspectFill
//                picture.kf.setImage(with: profilePic)
//            }
//            else{
//                print("default pic")
//                picture.image = #imageLiteral(resourceName: "emptyProfilePicture")
//            }
//        }
//        return picture
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
///*
//    Asks for Permission to use user's locations
//*/
//    func useCurrentLocations(){
//        // Ask for Authorisation from the User.
//        self.locationManager.requestAlwaysAuthorization()
//        
//        // For use in foreground
//        self.locationManager.requestWhenInUseAuthorization()
//        
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//            locationManager.startUpdatingLocation()
//        }
//    }
//
//    func prepareCancelButtons(){
//        self.cancelDetails.cornerRadius = self.cancelDetails.frame.height/2
//        self.cancelPrice.cornerRadius = self.cancelPrice.frame.height/2
//        self.cancelDetails.image = Icon.cm.clear
//        self.cancelPrice.image = Icon.cm.arrowBack
//    }
//    
//   
//}
//
//extension SellVC {
//    
//    func preparePopupForJobPosting(wage: String, time: String) -> PopupDialog{
//
//        let price = (Double(wage )!)*(Double(time )!)
//        let priceForStripe = Int(price*100)
//        let title = "Confirm"
//        let message = "We will authorize " + "$" + "\(price)" + " for your job. You can cancel your job at anytime before it has been confirmed and begun. If you cancel after it has been accepted, a small fee of $ 5.00 will be charged."
//
//        let popup = PopupDialog(title: title, message: message)
//
//        let continueButton = DefaultButton(title: "Continue", dismissOnTap: true) {
//
//            self.service.addJobToFirebase(jobTitle: self.jobTitleTF.text!, jobDetails: self.jobDetailsTF.text!, pricePerHour: self.pricePerHour.text!, numberOfHours: self.numberOfHoursTF.text!, locationCoord: self.currentLocation, chargeID: "charge_ID should be here")
//            
//
////            //Attempt to charge a payment
////            self.prepareAndAddBlurredLoader()
////            self.submitJobButton.isHidden = true
////            //LoadingAnimation initialize and play
////            MyAPIClient.sharedClient.authorizeCharge(amount: priceForStripe, completion: { charge_id in
////                //If no error when paying
////
////                self.removedBlurredLoader()
////                if charge_id != nil{
////                    //
////                    self.service.addJobToFirebase(jobTitle: self.jobTitleTF.text!, jobDetails: self.jobDetailsTF.text!, pricePerHour: self.pricePerHour.text!, numberOfHours: self.numberOfHoursTF.text!, locationCoord: self.currentLocation, chargeID: charge_id!)
////
////                    self.jobPriceViewConstraint.constant = 1600
////                    UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
////                    self.postJobButton.isHidden = false
////                    self.resetTextFields()
////                    self.prepareBannerForPost()
////                    print("Sucessfully posted job")
////                    self.submitJobButton.isHidden = false
////
////                    return
////                }
////                //If error when paying
////                else{
////                    let errorPopup = PopupDialog(title: "Error processing payment.", message:"Your payment method has failed, or none has been added. Please check your payment methods by tapping on the menu, and selecting payment methods.")
////                    self.present(errorPopup, animated: true, completion: {
////                        self.submitJobButton.isHidden = false
////                    })
////                    return
////                }
////            })
//        }
//
//        let cancelButton = CancelButton(title: "Cancel") {
//            print("Job cancelled")
//        }
//        popup.addButtons([continueButton,cancelButton])
//        return popup
//    }
//    
//    
//    func prepareBannerForAccept(){
//        let banner = NotificationBanner(title: "Success", subtitle: "Accepted Job", leftView: postedJobAnimation, style: .success)
//        banner.show()
//        check.play()
//    }
//    
////    func prepareAndShowPopup(job: Job) -> PopupDialog{
////
////
////        // Prepare the popup assets
////        let title = "Requirement: " + "\(job.maxTime)" + " Hours, for: " + "$" + "\(job.wage_per_hour)" + "/Hour"
////        let message = job.description
////
////        // Create the dialog
////        let popup = PopupDialog(title: title, message: message)
////
////        // Create buttons
////        let buttonOne = CancelButton(title: "Cancel") {
////            print("Job Cancelled")
////        }
////
////
////        let buttonTwo = DefaultButton(title: "Accept job") {
////
////            popup.dismiss()
////            self.service.acceptPressed(job: job, user: Auth.auth().currentUser!) { (deviceToken) in
////                let title = "Blip"
////                let displayName = (Auth.auth().currentUser?.displayName)!
////                let body = "Your Job Has Been Accepted By \(displayName)"
////                let device = deviceToken
////                var headers: HTTPHeaders = HTTPHeaders()
////                self.acceptedJob = job
////                headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
////
////                let notification = ["to":"\(device)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
////
////                Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
////
////                    if let err = response.error{
////                        print(err.localizedDescription)
////                    }
////                    else{
//////                        self.preparePopupForJobAccepting(job: job)
////                    }
////                })
////                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "acceptedNotification"), object: nil)
////
////
////            }
////            print("Accepted Job")
////            self.prepareBannerForAccept()
////        }
////        popup.addButtons([buttonTwo, buttonOne])
////        return popup
////    }
//
////    func preparePopupForCurrentPost(job: Job){
////
////        let dialogController = AZDialogViewController(title: job.title,
////                                                      message: job.description)
////
////        dialogController.showSeparator = true
////
////        dialogController.dismissDirection = .bottom
////
////        dialogController.imageHandler = { (imageView) in
////
////            self.service.getUserInfo(hash: job.jobOwnerEmailHash, completion: { (user) in
////
////                if let blipUser = user{
////                    imageView.kf.setImage(with: blipUser.photoURL)
////                    imageView.contentMode = .scaleAspectFill
////                }
////            })
////            return true
////        }
////
////        dialogController.addAction(AZDialogAction(title: "Cancel Post", handler: { [weak self] (dialog) -> (Void) in
////
////            dialogController.dismiss()
////            self?.preparePopupForJobCancel()
////        }))
////
////        dialogController.buttonStyle = { (button,height,position) in
////
////            button.backgroundColor = #colorLiteral(red: 0.9357799888, green: 0.4159773588, blue: 0.3661105633, alpha: 1)
////            button.setTitleColor(UIColor.white, for: [])
////            button.layer.masksToBounds = true
////            button.tintColor = .white
////        }
////
////        dialogController.blurBackground = true
////        dialogController.blurEffectStyle = .dark
////
////
////
////        dialogController.dismissWithOutsideTouch = true
////
////        dialogController.show(in: self)
////    }
////
////    func preparePopupForJobCancel(){
////
////        let popup = PopupDialog(title: "Confirm", message: "Are you sure you want to cancel your job post?")
////
////        let yes = DefaultButton(title: "Yes"){
////            popup.dismiss()
////            self.service.cancelJobPost(job: self.currentJobPost!)
////        }
////
////        let no = CancelButton(title: "No"){
////            popup.dismiss()
////            self.preparePopupForCurrentPost(job: self.currentJobPost!)
////        }
////
////        popup.addButtons([yes, no])
////
////        self.present(popup, animated: true, completion: nil)
////    }
////
//    //Resets text fields on job form after it is no longer needed.
//    func resetTextFields(){
//        pricePerHour.text! = ""
//        numberOfHoursTF.text = ""
//        jobTitleTF.text = ""
//        jobDetailsTF.text = ""
//    }
//    
//    
//}


