//
//  SellVC02.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2017-07-19.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Firebase
import Lottie
import CoreLocation
import Material
import FBSDKLoginKit
import Mapbox
import PopupDialog
import Alamofire
import Stripe
import SHSearchBar
import Kingfisher
import NotificationBannerSwift
import AZDialogView

class SellVC: UIViewController,  MGLMapViewDelegate, CLLocationManagerDelegate, STPPaymentContextDelegate, SHSearchBarDelegate {

    
    @IBOutlet weak var rootView: UIView!
    @IBOutlet weak var scheduleJob: TextField!
    @IBOutlet weak var submitJobButton: RaisedButton!
    @IBOutlet weak var jobDetailsView: UIView!
    @IBOutlet weak var jobPriceView: UIView!
    @IBOutlet weak var cancelPrice: RaisedButton!
    @IBOutlet weak var cancelDetails: RaisedButton!
    @IBOutlet weak var numberOfHoursTF: TextField!
    @IBOutlet weak var pricePerHour: TextField!
    @IBOutlet weak var jobPriceViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var jobDetailsTF: TextView!
    @IBOutlet weak var jobTitleTF: TextField!
    @IBOutlet weak var jobDetailsConstraint: NSLayoutConstraint!
    @IBOutlet weak var postJobButton: RaisedButton!
    @IBOutlet weak var MapView: MGLMapView!
    fileprivate var viewJobButton: FlatButton!
    var rasterSize: CGFloat = 11.0
    var viewConstraints: [NSLayoutConstraint]?
    let cardHeight: CGFloat = 600
    let cardWidth: CGFloat = 300
    var yPosition:CGFloat = 45
    var scrollViewContentSize: CGFloat = 0
    var dbRef: DatabaseReference!
    var pointAnnotations : [CustomMGLAnnotation] = []
    var allAvailableJobs: [Job] = []
    var acceptedJob: Job!
    let service = ServiceCalls()
    var menuShowing = false
    var hamburgerAnimation: LOTAnimationView!
    var locationManager = CLLocationManager()
    let camera = MGLMapCamera()
    var currentLocation: CLLocationCoordinate2D!
    var paymentContext: STPPaymentContext? = nil
    let backendBaseURL: String? = "https://us-central1-blip-c1e83.cloudfunctions.net/"
    let stripePublishableKey = "pk_test_K45gbx2IXkVSg4pfmoq9SIa9"
    let appleMerchantID: String? = nil
    let companyName = "Blip"
    var timer : Timer!
    var searchBar: SHSearchBar!
    var latestAccepted:Job!
    let loadingAnimation = LOTAnimationView(name: "loading")
    var applicantEHash:String!
    var filteredJobs: [MGLPointAnnotation] = []
    var allAnnotations: [String:CustomMGLAnnotation]!
    var accepterHash: String?
    var applicantInfo: [String:AnyObject]!
    let postedJobAnimation = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    let check = LOTAnimationView(name: "check")
    let jobAccepterAnnotation = CustomMGLAnnotation()
    var currentJobPost: Job?
    var accepterUserObject: BlipUser?
    var connectivity = Connectivity()
    var internet:Bool!
    
    let userDefault = UserDefaults.standard
    
    ////////////////////////Functions associated with the controller go here//////////////////////////
    
    override func viewDidLoad() {
        self.MapView.delegate = self
        MapView.compassView.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
        prepareCancelButtons()
        self.hideKeyboardWhenTappedAround()
        prepareTitleTextField()
        preparePostJobButton()
        useCurrentLocations()
        prepareJobForm()
        self.prepareSearchBar()
        self.prepareBannerLeftView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //checking for internet on first reach of the viewcontroller
        connectivity?.whenReachable = {_ in
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                self.prepareMap()   // Prepare map thing on the main thread if there is internet on first run
                self.saveUserInfoInUserDefault()    //This is to access user info to use to setup profile page
            }
        }
        connectivity?.whenUnreachable = {_ in   // No internet on start up
            self.view.isUserInteractionEnabled = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(connectivityChanged), name: Notification.Name.reachabilityChanged, object: connectivity)
        do{
            try connectivity?.startNotifier()
        }catch{
            print("Could not start the notifier")
        }
        
        self.saveUserInfoInUserDefault()    //This is to access user info to use to setup profile page
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func saveUserInfoInUserDefault(){
        service.getUserInfo(hash: service.emailHash) { (currUser) in
            var dataDict:[String:AnyObject] = [:]
//            dataArr.append(currUser?.name)
            dataDict["name"] = currUser?.name as AnyObject
//            dataArr.append(currUser?.rating)
            dataDict["rating"] = currUser?.rating as AnyObject
//            dataArr.append((currUser?.photoURL)!.absoluteString)
            dataDict["photoUrl"] = currUser?.photoURL?.absoluteString as AnyObject
            if let completedJobs = currUser?.completedJobs{
//                dataArr.append(completedJobs.count)
                dataDict["num_completed_jobs"] = completedJobs.count as AnyObject
            }
            self.userDefault.setValue(dataDict, forKey: "userProfileInfo")
        }
    }
    
    //Internet Notification for when internet is lost or came back
    @objc func connectivityChanged(notification: Notification){
        let connectivity = notification.object as! Connectivity
        if (connectivity.connection == .wifi || connectivity.connection == .cellular){
            self.internet = true
            DispatchQueue.main.async {
//                self.prepareMap()   // When it regains connection try to prepare map on main thread
                print("REGAINED CONNECTION")
            }
            
        }else{
            self.internet = false
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = false
                self.present(self.popupForNoInternet(), animated: true, completion: nil)
            }
            print("Connection Gone")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "startJobFromSellVC"{
            if let dest = segue.destination as? StartJob{
                dest.job = self.acceptedJob
            }
        }
        
        if segue.identifier == "endJobFromSellVC"{
            
            if let dest = segue.destination as? EndJob{
                dest.job = self.acceptedJob
            }
        }
        
    }

    //Sets the camera for the mapview and sets current location to users current locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.camera.centerCoordinate = locValue
        self.camera.altitude = CLLocationDistance(11000)
        self.camera.pitch = CGFloat(60)
        self.MapView.setCenter(locValue, zoomLevel: 5, direction: 0, animated: false)
        self.MapView.setZoomLevel(7, animated: true)
        self.MapView.setCamera(camera, withDuration: 4, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        currentLocation = locValue
        service.updateJobAccepterLocation(location: locValue)
        manager.stopUpdatingLocation()
    }

    //When the postJob red button is pressed
    @IBAction func postJobPressed(_ sender: Any) {
    
        self.postJobButton.isHidden = true
        self.jobDetailsConstraint.constant = 77
        UIView.animate(withDuration: 0.5, animations: {self.view.layoutIfNeeded()})
 
    }
    
    
    
    
    //When next is pressed on the Job details form
    @IBAction func nextPressedOnDetails(_ sender: Any) {
        
        if (!jobDetailsTF.isEmpty && !jobTitleTF.isEmpty ){
            jobDetailsConstraint.constant = 800
            UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
            jobPriceViewConstraint.constant = 77
            UIView.animate(withDuration: 2, animations: {self.view.layoutIfNeeded()})
            
        }
    }
    
    //When submit is pressed after the job price form
    @IBAction func submitJob(_ sender: Any) {
        
        if (CLLocationManager.locationServicesEnabled()){
            if (pricePerHour.text == "" || numberOfHoursTF.text == "" || jobTitleTF.text == "" ||
                jobDetailsTF.text == ""){
                
                print("Empty fields, please check again")
                return
            }
                
            else{   // add job things to firebase
                
                let popup = preparePopupForJobPosting(wage: pricePerHour.text!, time: numberOfHoursTF.text!)
                self.present(popup, animated: true, completion: nil)
                
            }
            
        }
        else{
            let locationServicesPopup = PopupDialog(title: "Error", message: "Please enable location services to allow us to determine the location for your job")
            self.present(locationServicesPopup, animated: true)
            print("Location not enabled")
            return
        }
        
    }
    
    //When you cancel the details, the view is animated here
    @IBAction func cancelDetailsPressed(_ sender: Any) {
        self.resetTextFields()
        jobDetailsConstraint.constant = 800
        UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
        postJobButton.isHidden = false
    }
    
    //When you cancel price by pressing back, the view is animated here
    @IBAction func cancelPricePressed(_ sender: Any) {

        jobPriceViewConstraint.constant = 1600
        UIView.animate(withDuration: 1.5, animations: {self.view.layoutIfNeeded()})
        jobDetailsConstraint.constant = 77
        UIView.animate(withDuration: 2, animations: {self.view.layoutIfNeeded()})
        
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        
        if let anno = annotation as? CustomMGLAnnotation{
            let popup = self.prepareAndShowPopup(job: anno.job!)
            self.present(popup, animated: true, completion: nil)
        }
        
    }
    
    //Loads the profilePicture for the map annotation
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        let annotationView = CustomAnnotationView()
        if let castedAnnotation = annotation as? CustomMGLAnnotation{
            
            annotationView.frame = CGRect(x: 0, y: 0, width: 35, height: 35 )
            let profileImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35 ))
            profileImage.contentMode = .scaleAspectFill
            profileImage.kf.setImage(with: castedAnnotation.photoURL)
            profileImage.isUserInteractionEnabled = true
            annotationView.addSubview(profileImage)
            annotationView.cornerRadius = annotationView.frame.size.height/2
            annotationView.isUserInteractionEnabled = true
        }
        return annotationView
        
    }
    
    
    //Search feature to filter jobs by title, needs additional work to be used properly
    func searchBarDidEndEditing(_ searchBar: SHSearchBar) {
        let searchText = searchBar.text
        if !(searchText?.isEmpty)!{
            for j in allAvailableJobs {
                if (j.title.lowercased().range(of: searchText!.lowercased()) != nil) {

                    let point = CustomMGLAnnotation()
                    point.coordinate = j.location.coordinate
                    point.title = j.title
                    point.subtitle = ("$"+"\(j.wage_per_hour)"+"/Hour")
                    filteredJobs.append(point)
                }
            }
            print("Runs code")
            self.MapView.removeAnnotations(pointAnnotations)
            self.MapView.addAnnotations(filteredJobs)
        }
    }
    
    func searchBarShouldClear(_ searchBar: SHSearchBar) -> Bool {
        self.MapView.removeAnnotations(filteredJobs)
        self.MapView.addAnnotations(pointAnnotations)

        return true
    }
    
    
    //Prepares custom textfields for the job form
    func prepareTitleTextField(){
        
        self.pricePerHour.font = UIFont(name: "Century Gothic", size: 17)
        self.pricePerHour.textColor = Color.white
        self.pricePerHour.placeholderActiveColor = Color.white
        self.pricePerHour.detailColor = Color.white
        self.pricePerHour.placeholderNormalColor = Color.white
        self.numberOfHoursTF.font = UIFont(name: "Century Gothic", size: 17)
        self.numberOfHoursTF.textColor = Color.white
        self.numberOfHoursTF.placeholderActiveColor = Color.white
        self.numberOfHoursTF.detailColor = Color.white
        self.numberOfHoursTF.placeholderNormalColor = Color.white
        self.jobTitleTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        self.jobDetailsTF.placeholder = "Enter a job description; here is where you can be clear and concise with the full details of your job"
        self.jobDetailsTF.placeholderColor = Color.white
        self.jobDetailsTF.font = UIFont(name: "Century Gothic", size: 17)
        self.jobDetailsTF.textColor = Color.white
        self.jobTitleTF.font = UIFont(name: "Century Gothic", size: 17)
        self.jobTitleTF.textColor = Color.white
        self.jobTitleTF.placeholder = "Job Title"
        self.jobTitleTF.placeholderActiveColor = Color.white
        self.jobTitleTF.detailLabel.text = "A short title for your job"
        self.jobTitleTF.detailColor = Color.white
        self.jobTitleTF.placeholderNormalColor = Color.white
        self.scheduleJob.font = UIFont(name: "Century Gothic", size: 17)
        self.scheduleJob.textColor = Color.white
        self.scheduleJob.placeholderActiveColor = Color.white
        self.scheduleJob.detailColor = Color.white
        self.scheduleJob.placeholderNormalColor = Color.white
    }
    
    
    //Prepares the post job button
    func preparePostJobButton(){
        postJobButton.image = Icon.cm.pen
        postJobButton.cornerRadius = postJobButton.frame.height/2
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    //Loads a rating animation using the users rating, and puts this when the map annotation is clicked
    func mapView(_ mapView: MGLMapView, leftCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        
        let animation = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 50))
        let ratingAnimation = LOTAnimationView(name: "5_stars")
        animation.handledAnimation(Animation: ratingAnimation)
        var rating = CGFloat(0)
        
        if let anno = annotation as? CustomMGLAnnotation{
            rating = CGFloat((anno.job?.jobOwnerRating)!/5)
        }        
        ratingAnimation.play(toProgress: rating, withCompletion: nil)
        return animation
    }
    
/**
    //Loads an animation
 */
    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        let picture = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        picture.cornerRadius = picture.frame.height/2
        
        if let anno = annotation as? CustomMGLAnnotation{
            if let profilePic = anno.job?.jobOwnerPhotoURL{
                picture.contentMode = .scaleAspectFill
                picture.kf.setImage(with: profilePic)
            }
            else{
                print("default pic")
                picture.image = #imageLiteral(resourceName: "emptyProfilePicture")
            }
        }
        return picture
    }
    
    


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func useCurrentLocations(){
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }
    
    func prepareCancelButtons(){
        self.cancelDetails.cornerRadius = self.cancelDetails.frame.height/2
        self.cancelPrice.cornerRadius = self.cancelPrice.frame.height/2
        self.cancelDetails.image = Icon.cm.clear
        self.cancelPrice.image = Icon.cm.arrowBack
    }
    
   
}

extension SellVC {
    
    func preparePopupForJobPosting(wage: String, time: String) -> PopupDialog{
        
        let price = (Double(wage )!)*(Double(time )!)
        let priceForStripe = Int(price*100)
        let title = "Confirm"
        let message = "We will authorize " + "$" + "\(price)" + " for your job. You can cancel your job at anytime before it has been confirmed and begun. If you cancel after it has been accepted, a small fee of $ 5.00 will be charged."
        
        let popup = PopupDialog(title: title, message: message)
        
        let continueButton = DefaultButton(title: "Continue", dismissOnTap: true) {
            
            
            //Attempt to charge a payment
            self.prepareAndAddBlurredLoader()
            self.submitJobButton.isHidden = true
            //LoadingAnimation initialize and play
            MyAPIClient.sharedClient.authorizeCharge(amount: priceForStripe, completion: { charge_id in
                //If no error when paying
                
                self.removedBlurredLoader()
                if charge_id != nil{
                    //
                    self.service.addJobToFirebase(jobTitle: self.jobTitleTF.text!, jobDetails: self.jobDetailsTF.text!, pricePerHour: self.pricePerHour.text!, numberOfHours: self.numberOfHoursTF.text!, locationCoord: self.currentLocation, chargeID: charge_id!)
                    
                    self.jobPriceViewConstraint.constant = 1600
                    UIView.animate(withDuration: 1, animations: {self.view.layoutIfNeeded()})
                    self.postJobButton.isHidden = false
                    self.resetTextFields()
                    self.prepareBannerForPost()
                    print("Sucessfully posted job")
                    self.submitJobButton.isHidden = false
                    
                    return
                }
                //If error when paying
                else{
                    let errorPopup = PopupDialog(title: "Error processing payment.", message:"Your payment method has failed, or none has been added. Please check your payment methods by tapping on the menu, and selecting payment methods.")
                    self.present(errorPopup, animated: true, completion: {
                        self.submitJobButton.isHidden = false
                    })
                    return
                }
            })
        }

        let cancelButton = CancelButton(title: "Cancel") {
            print("Job cancelled")
        }
        popup.addButtons([continueButton,cancelButton])
        return popup
    }
    
    
    func prepareBannerForAccept(){
        
        let banner = NotificationBanner(title: "Success", subtitle: "Accepted Job", leftView: postedJobAnimation, style: .success)
        banner.show()
        check.play()
    }
    
    func removedBlurredLoader(){
        
        self.loadingAnimation.stop()
        if let loadingViewAfterStripe = self.view.viewWithTag(100){
            loadingViewAfterStripe.removeFromSuperview()
        }
        if let blurredViewAfterStripe = self.view.viewWithTag(101){
            blurredViewAfterStripe.removeFromSuperview()
        }
    }
    
    func isBlurredLoaderPresent() -> Bool{
        
        if self.view.viewWithTag(100) != nil{
            return true
        }
        else{
            return false
        }
    }
    
    func prepareAndAddBlurredLoader(){
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.tag = 101
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(blurEffectView)
        let loadingView = UIView()
        loadingView.tag = 100
        loadingView.frame.size = CGSize(width: 200, height: 200)
        loadingView.frame.origin = self.view.bounds.origin
        loadingView.center = self.view.convert(self.view.center, from: loadingView)
        loadingView.handledAnimation(Animation: self.loadingAnimation)
        self.view.addSubview(loadingView)
        self.loadingAnimation.play()
        self.loadingAnimation.loopAnimation = true
    }
    
    func prepareAndShowPopup(job: Job) -> PopupDialog{
        
        
        // Prepare the popup assets
        let title = "Requirement: " + "\(job.maxTime)" + " Hours, for: " + "$" + "\(job.wage_per_hour)" + "/Hour"
        let message = job.description
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message)
        
        // Create buttons
        let buttonOne = CancelButton(title: "Cancel") {
            print("Job Cancelled")
        }
        
        
        let buttonTwo = DefaultButton(title: "Accept job") {
            
            popup.dismiss()
            self.service.acceptPressed(job: job, user: Auth.auth().currentUser!) { (deviceToken) in
                let title = "Blip"
                let displayName = (Auth.auth().currentUser?.displayName)!
                let body = "Your Job Has Been Accepted By \(displayName)"
                let device = deviceToken
                var headers: HTTPHeaders = HTTPHeaders()
                self.acceptedJob = job
                headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
                
                let notification = ["to":"\(device)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
                
                Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                    
                    if let err = response.error{
                        print(err.localizedDescription)
                    }
                    else{
                        self.preparePopupForJobAccepting(job: job)
                    }
                })
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "acceptedNotification"), object: nil)
                
                
            }
            print("Accepted Job")
            self.prepareBannerForAccept()
        }
        popup.addButtons([buttonTwo, buttonOne])
        return popup
    }

    func preparePopupForCurrentPost(job: Job){
        
        let dialogController = AZDialogViewController(title: job.title,
                                                      message: job.description)
        
        dialogController.showSeparator = true
        
        dialogController.dismissDirection = .bottom
        
        dialogController.imageHandler = { (imageView) in
            
            self.service.getUserInfo(hash: job.jobOwnerEmailHash, completion: { (user) in
                
                if let blipUser = user{
                    imageView.kf.setImage(with: blipUser.photoURL)
                    imageView.contentMode = .scaleAspectFill
                }
            })
            return true
        }
        
        dialogController.addAction(AZDialogAction(title: "Cancel Post", handler: { [weak self] (dialog) -> (Void) in
            
            dialogController.dismiss()
            self?.preparePopupForJobCancel()
        }))
        
        dialogController.buttonStyle = { (button,height,position) in
            
            button.backgroundColor = #colorLiteral(red: 0.9357799888, green: 0.4159773588, blue: 0.3661105633, alpha: 1)
            button.setTitleColor(UIColor.white, for: [])
            button.layer.masksToBounds = true
            button.tintColor = .white
        }
        
        dialogController.blurBackground = true
        dialogController.blurEffectStyle = .dark
        
        
        
        dialogController.dismissWithOutsideTouch = true
        
        dialogController.show(in: self)
    }
    
    func preparePopupForJobCancel(){

        let popup = PopupDialog(title: "Confirm", message: "Are you sure you want to cancel your job post?")
        
        let yes = DefaultButton(title: "Yes"){
            popup.dismiss()
            self.service.cancelJobPost(job: self.currentJobPost!)
        }
        
        let no = CancelButton(title: "No"){
            popup.dismiss()
            self.preparePopupForCurrentPost(job: self.currentJobPost!)
        }
        
        popup.addButtons([yes, no])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    //Resets text fields on job form after it is no longer needed.
    func resetTextFields(){
        pricePerHour.text! = ""
        numberOfHoursTF.text = ""
        jobTitleTF.text = ""
        jobDetailsTF.text = ""
    }
    
    
}


