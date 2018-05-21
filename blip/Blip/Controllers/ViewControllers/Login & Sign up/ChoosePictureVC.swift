//
//  ChoosePictureVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-03.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material
import Pastel
import Lottie
import PopupDialog
import Firebase
import Alamofire

class ChoosePictureVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var cameraAnimationView: UIView!
    @IBOutlet weak var goButton: RaisedButton!
    var userInfoDict:[String:String]!
    let service = ServiceCalls.instance
    var userUploadedPicture = false
    var continuePressed_num = 0
    var newUser: User?
    let userDefault = UserDefaults.standard
    var userCredDict:[String:String]!
    let loginCredentials = "loginCredentials"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        prepareGradientView()
        setupImageView()
        setupGoButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        prepareGradientView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareCameraAnimation()
    }
    
    fileprivate func prepareGradientView(){
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }
    
    fileprivate func setupImageView(){
        profileImageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profileImageView.addGestureRecognizer(gesture)
        profileImageView.layer.cornerRadius = 90
        profileImageView.layer.masksToBounds = true
    }
    
    fileprivate func saveInfoInUserDefault(email: String, picture:String?, emailHash:String){
        self.userCredDict = [:]
        self.userCredDict["email"] = email
        self.userCredDict["photoURL"] = picture ?? ""
        self.userCredDict["emailHash"] = emailHash
        self.userCredDict["currentDevice"] = AppDelegate.DEVICEID
        self.userDefault.setValue(self.userCredDict, forKey: self.loginCredentials)
        return
    }
    
    fileprivate func setupGoButton(){
        goButton.addTarget(self, action: #selector(handleContinuePressed), for: .touchUpInside)
    }
    
    
    @objc fileprivate func handleContinuePressed(){
        service.createUser(firstName: userInfoDict["firstName"]!, lastName: userInfoDict["lastName"]!, email: userInfoDict["email"]!, password: userInfoDict["password"]!, image: profileImageView.image) { (errMsg, user) in
            if errMsg != nil{
                print(errMsg!)
                return
            }
            if let user = user as? User{
                MyAPIClient.sharedClient.createNewStripeAccount(email: self.userInfoDict["email"]!, firstName: self.userInfoDict["firstName"]!, lastName: self.userInfoDict["lastName"]!, completion: { (responseVal, error) in
                    if let error = error as? AFError{
                        print(error.errorDescription!)
                        return
                    }
                    self.saveInfoInUserDefault(email: self.userInfoDict["email"]!, picture: user.photoURL?.absoluteString, emailHash: self.service.emailHash)
                })
                
            }
        }
    }
    
    @objc fileprivate func handleImageTap(){
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
    
    ///IMPORTANT BUG: loading animation over animation
    fileprivate func prepareCameraAnimation(){
        let cameraAnimation = LOTAnimationView(name: "camera")
        cameraAnimationView.handledAnimation(Animation: cameraAnimation, width: 2, height: 2)
        cameraAnimation.isUserInteractionEnabled = false
        cameraAnimation.play()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        profileImageView.image = image
        userUploadedPicture = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        userUploadedPicture = false
        print(userUploadedPicture)
    }
    
    
}
