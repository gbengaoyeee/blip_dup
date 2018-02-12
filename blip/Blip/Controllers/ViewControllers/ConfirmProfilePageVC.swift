//
//  ConfirmPageVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 9/23/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//


import UIKit
import Firebase
import FirebaseStorage
import Lottie
import Pastel
import Kingfisher
import Alamofire
import Cosmos
import Material

class ConfirmProfilePageVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
//    var applicantInfo: [String:AnyObject]!
    var currUser: BlipUser?
    var jobAccepter: BlipUser?
    var userChangedProfilePic = false
    var userRef:DatabaseReference!
    @IBOutlet weak var gradientView: PastelView!
    @IBOutlet weak var scrollForReviews: UIScrollView!
    @IBOutlet weak var ratingAnimationView: CosmosView!
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var totalJobs: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var closeButton: RaisedButton!
    
    @IBOutlet weak var hireButton: UIButton!
    let ratingAnimation = LOTAnimationView(name: "5_stars")
    var picURL: URL?
//    var job: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.closeButton.image = Icon.cm.close
        self.navigationController?.navigationBar.isHidden = false
        prepareInformation()
        self.gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),#colorLiteral(red: 0.7605337501, green: 0.7767006755, blue: 0.7612826824, alpha: 1)])
        profilePic.isUserInteractionEnabled = true
        profilePic.cornerRadius = profilePic.frame.height/2
        if let completedJobs = currUser?.completedJobs{
            totalJobs.text = "\(completedJobs.count)"
        }
        if let jobAccepter = self.jobAccepter{
            picURL = jobAccepter.photoURL
            profilePic.kf.setImage(with: picURL!)
        }else{
            hireButton.isHidden = true
            picURL = currUser!.photoURL
            profilePic.kf.setImage(with: picURL!)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.gradientView.startAnimation()
        
        
        if let providerData = Auth.auth().currentUser?.providerData{
            for userInfo in providerData {
                if userInfo.providerID == "facebook.com" {
                    print("FACEBOOK")
                }
                else{// user can change profile picture
                    print("Bullsiza")
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(gesture:)))
                    profilePic.addGestureRecognizer(tapGesture)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.gradientView.startAnimation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   @objc func imageTapped(gesture: UIGestureRecognizer){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionPopup = UIAlertController(title: "Photo Source", message: "Choose Image", preferredStyle: .actionSheet)
        
        actionPopup.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionPopup.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionPopup.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionPopup, animated: true, completion: nil)
    }
    
    func prepareInformation() {
        if let jobAccepter = self.jobAccepter{
            self.fullNameLabel.text = jobAccepter.name
            self.ratingAnimationView.rating = Double(jobAccepter.rating!)
        }else{
            self.fullNameLabel.text = currUser!.name
            self.ratingAnimationView.rating = Double((currUser?.rating)!)
        }
        
    }
    
    @IBAction func confirmclicked(_ sender: UIButton) {
        let title = "Blip"
//        let body = "Your Job Has Been Accepted By \(Auth.auth().currentUser?.displayName ?? "someone")"
        let body = "You have been awarded the task"
        let device = (jobAccepter?.currentDevice)!
        var headers: HTTPHeaders = HTTPHeaders()
        
        headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
        
        let notification = ["to":"\(device)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
        
        Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "confirmedNotification"), object: nil)
    }
    
    @IBAction func dismissButton(_ sender: UIButton) {
        let helper = HelperFunctions()
        self.userRef = Database.database().reference().child("Users").child(helper.MD5(string: (Auth.auth().currentUser?.email)!))
        if (userChangedProfilePic){
            
            let storageRef = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/").child("profile_image").child(helper.MD5(string: (Auth.auth().currentUser?.email)!))
            let imageData = UIImageJPEGRepresentation((profilePic.image)!, 0.1)
            
            storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print(error!.localizedDescription)
                    return
                }
                let profileImgURL = metadata?.downloadURL()?.absoluteString
                let profile = Auth.auth().currentUser?.createProfileChangeRequest()
                profile?.photoURL = URL(string: profileImgURL!)
                profile?.commitChanges(completion: { (err) in
                    if err != nil{
                        return
                    }
                    let imgValues:[String:String] = ["photoURL":profileImgURL!]
                    self.userRef.updateChildValues(imgValues)
                    self.dismiss(animated: true, completion: nil)
                })
                
            })
            
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profilePic.image = image
        userChangedProfilePic = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
