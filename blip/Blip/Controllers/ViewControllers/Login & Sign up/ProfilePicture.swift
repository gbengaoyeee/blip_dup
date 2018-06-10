//
//  ProfilePicture.swift
//  Blip
//
//  Created by Srikanth Srinivas on 12/17/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Pastel
import Firebase
import FirebaseStorage
import PopupDialog
import Material

class ProfilePicture: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var gradientView: PastelView!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var continueButt:UIButton!
    let helper = HelperFunctions()
    var userRef: DatabaseReference!
    var userUploadedPicture = false
    var connectivity = Connectivity()
    var internet:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        continueButt.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        
        profilePicture.image = UIImage(named: "emptyProfilePicture")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePicture.imageTapped(gesture:)))
        userRef = Database.database().reference().child("Couriers").child(helper.MD5(string: (Auth.auth().currentUser?.email)!))
        self.navigationController?.navigationBar.isHidden = true
        profilePicture.layer.cornerRadius = profilePicture.frame.width/2
        // add it to the image view;
        profilePicture.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        profilePicture.isUserInteractionEnabled = true
        // Do any additional setup after loading the view.
        gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //Doing internet stuff
        connectivity?.whenReachable = {_ in
            
        }
        connectivity?.whenUnreachable = {_ in
            DispatchQueue.main.async {
                print("NO INTERNET WHEN I STARTED")
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(connectivityChanged), name: Notification.Name.reachabilityChanged, object: connectivity)
        do{
            try connectivity?.startNotifier()
        }catch{
            print("Could not start the notifier")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Second")
    }
    
    @objc func connectivityChanged(notification: Notification){
        let connectivity = notification.object as! Connectivity
        if (connectivity.connection == .wifi || connectivity.connection == .cellular){
            self.internet = true
            print("REGAINED CONNECTION")
        }else{
            self.internet = false
            print("Connection Gone")
        }
    }
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc fileprivate func handleContinue(){
        if !(internet){
            let popup = popupForNoInternet()
            self.present(popup, animated: true, completion: nil)
            return
        }
        
        _ = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/").child("profile_image").child(helper.MD5(string: (Auth.auth().currentUser?.email)!))
        
        if !userUploadedPicture{
            let errorPopup = PopupDialog(title: "Error", message: "Please upload a profile picture")
            self.present(errorPopup, animated: true, completion: nil)
        }
//        else{
//            if let profileImg = profilePicture.image, let imageData = UIImageJPEGRepresentation(profileImg, 0.1){
//                storageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
//                    if error != nil{
//                        return
//                    }
//
//                    let profileImgURL = metadata?.downloadURL()?.absoluteString
//                    let profile = Auth.auth().currentUser?.createProfileChangeRequest()
//                    profile?.photoURL = URL(string: profileImgURL!)
//                    profile?.commitChanges(completion: { (err) in
//                        if err != nil{
//                            return
//                        }
//                        let imgValues:[String:Any] = ["photoURL":profileImgURL!]
//                        self.userRef.updateChildValues(imgValues)
//                        self.performSegue(withIdentifier: "endSignUp", sender: nil)
//                    })
//                })
//            }
//        }
    }

//    @IBAction func continuePressed(_ sender: UIButton) {
//        if !(internet){
//            let popup = popupForNoInternet()
//            self.present(popup, animated: true, completion: nil)
//            return
//        }
//
//        let storageRef = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/").child("profile_image").child(helper.MD5(string: (Auth.auth().currentUser?.email)!))
//
//        if !userUploadedPicture{
//            let errorPopup = PopupDialog(title: "Error", message: "Please upload a profile picture")
//            self.present(errorPopup, animated: true, completion: nil)
//        }
//        else{
//            if let profileImg = profilePicture.image, let imageData = UIImageJPEGRepresentation(profileImg, 0.1){
//                storageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
//                    if error != nil{
//                        return
//                    }
//
//                    let profileImgURL = metadata?.downloadURL()?.absoluteString
//                    let profile = Auth.auth().currentUser?.createProfileChangeRequest()
//                    profile?.photoURL = URL(string: profileImgURL!)
//                    profile?.commitChanges(completion: { (err) in
//                        if err != nil{
//                            return
//                        }
//                        let imgValues:[String:Any] = ["photoURL":profileImgURL!]
//                        self.userRef.updateChildValues(imgValues)
//                        self.performSegue(withIdentifier: "endSignUp", sender: nil)
//                    })
//                })
//            }
//        }
//    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profilePicture.image = image
        userUploadedPicture = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        userUploadedPicture = false
    }
    
    
    private func popupForNoInternet()-> PopupDialog {
        let title = "Internet Unavailable"
        let message = "Please connect to the internet and try again"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }

}
