//
//  EmailVerifyVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 8/6/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Lottie
import Pastel
import Firebase
import Material
import PopupDialog

class EmailVerifyVC: UIViewController {

    @IBOutlet weak var gradientView: PastelView!
    @IBOutlet weak var emailTF: TextField!
    @IBOutlet weak var passwordTF: TextField!
    @IBOutlet weak var continueButtonEmail: UIButton!
    @IBOutlet weak var continueTwo: RaisedButton!
    @IBOutlet weak var emailCheckAnimation: UIView!
    var firstName : String!
    var lastName: String!
    var dbRef : DatabaseReference!
    var newUserUID: String!
    var checkEmail = LOTAnimationView()
    var loadingAnimation = LOTAnimationView()
    var user: User?
    var emailPopup: PopupDialog?
    var connectivity = Connectivity()
    var internet:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkEmail = self.view.returnHandledAnimation(filename: "check", subView: emailCheckAnimation, tagNum: 1)
        dbRef = Database.database().reference()
        self.prepareTitleTextField()
        self.navigationController?.navigationBar.isHidden = false
        gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.continueButtonEmail.makeButtonAppear()
        
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
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func continueEnter(_ sender: Any) {// For when return is pressed on keyboard
        self.dismissKeyboard()
        
        if !(internet){
            let popup = popupForNoInternet()
            self.present(popup, animated: true, completion: nil)
            return
        }
        
        if (emailTF.text?.isEmpty != true && passwordTF.text?.isEmpty != true){
            self.emailTF.isUserInteractionEnabled = false
            self.passwordTF.isUserInteractionEnabled = false
            presentLoadingView()
            Auth.auth().createUser(withEmail: self.emailTF.text!, password: self.passwordTF.text!, completion: { (user, error) in
                if (error != nil){
                    self.errorAnimation()
                    self.emailTF.isUserInteractionEnabled = true
                    self.passwordTF.isUserInteractionEnabled = true
                    print(error!.localizedDescription)
                    return
                }
                else{// created user successfully
                    user?.sendEmailVerification(completion: { (err) in
                        if let error = err {
                            print(error.localizedDescription)
                            return
                        }
                        self.emailPopup = self.prepareEmailVerifyPopup(user: user!)
                        self.presentVerifyEmailPopup()
                        self.continueButtonEmail.isHidden = true
                        self.continueTwo.isHidden = false
                    })
                    
                }
            })
        }
    }
    
    @IBAction func continueButtonEmail(_ sender: UIButton) {
        if !(internet){
            let popup = popupForNoInternet()
            self.present(popup, animated: true, completion: nil)
            return
        }
        if (emailTF?.text?.isEmpty != true && passwordTF?.text?.isEmpty != true){
            self.emailTF.isUserInteractionEnabled = false
            self.passwordTF.isUserInteractionEnabled = false
            presentLoadingView()
            Auth.auth().createUser(withEmail: self.emailTF.text!, password: self.passwordTF.text!, completion: { (user, error) in
                if (error != nil){
                    self.errorAnimation()
                    self.emailTF.isUserInteractionEnabled = true
                    self.passwordTF.isUserInteractionEnabled = true
                    print(error!.localizedDescription)
                    return
                }
                else{// created user successfully
                    user?.sendEmailVerification(completion: { (err) in
                        if let error = err {
                            print(error.localizedDescription)
                            return
                        }
                        self.emailPopup = self.prepareEmailVerifyPopup(user: user!)
                        self.presentVerifyEmailPopup()
                        self.continueButtonEmail.isHidden = true
                        self.continueTwo.isHidden = false
                    })
                    
                }
            })
        }
    }

    @IBAction func continueTwo(_ sender: UIButton) {
        if !(internet){
            let popup = popupForNoInternet()
            self.present(popup, animated: true, completion: nil)
            return
        }
        if let user = Auth.auth().currentUser{
            user.reload(completion: { (error) in
                if let err = error{
                    print(err.localizedDescription)
                    return
                }
                if user.isEmailVerified{
                    self.continueTwo.isHidden = true
                    self.emailCheckAnimation.makeAnimationDissapear(tag: 2)
                    let profile = user.createProfileChangeRequest()
                    profile.displayName = "\(self.firstName!) \(self.lastName!)"
                    profile.commitChanges(completion: { (error2) in
                        if (error2 != nil){
                            self.errorAnimation()
                            print(error2!.localizedDescription)
                            return
                        }else{
                            self.addToDBAnimationAndSegue()
                        }
                    })
                }else{
                    self.emailPopup = self.prepareEmailVerifyPopup(user: user)
                    self.presentVerifyEmailPopup()
                }
            })
        }
    }
    
    
    func prepareTitleTextField(){
        self.emailTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        self.emailTF.font = UIFont(name: "Century Gothic", size: 17)
        self.emailTF.textColor = Color.white
        self.emailTF.placeholder = "Email"
        self.emailTF.placeholderActiveColor = Color.white
        self.emailTF.placeholderNormalColor = Color.white
        self.passwordTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        self.passwordTF.font = UIFont(name: "Century Gothic", size: 17)
        self.passwordTF.textColor = Color.white
        self.passwordTF.placeholder = "Password"
        self.passwordTF.placeholderActiveColor = Color.white
        self.passwordTF.placeholderNormalColor = Color.white
    }
    
    
    func prepareEmailVerifyPopup(user: User) -> PopupDialog{
        let title = "Verify your email"
        let message = "Please check your email for a verification link, then press continue after verifying"
        let emailVerifyPopup = PopupDialog(title: title, message: message)
        let resendButton = DefaultButton(title: "Resend verification Email", dismissOnTap: false) {
            user.sendEmailVerification(completion: { (error) in
                if error != nil{
                    print(error!.localizedDescription)
                    return
                }
            })
        }
        let continueButton = DefaultButton(title: "Continue", dismissOnTap: false){
            
            user.reload(completion: { (err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                if user.isEmailVerified{
                    emailVerifyPopup.dismiss()
                    self.continueTwo.isHidden = true
                    self.emailCheckAnimation.makeAnimationDissapear(tag: 2)
                    
                    let profile = user.createProfileChangeRequest()
                    profile.displayName = "\(self.firstName!) \(self.lastName!)"
                    profile.commitChanges(completion: { (error2) in
                        if (error2 != nil){
                            self.errorAnimation()
                            print(error2!.localizedDescription)
                            return
                        }
                        else{
                            self.addToDBAnimationAndSegue()
                        }
                    })
                }
                else{   // if user has not verified email
                    emailVerifyPopup.shake()
                }
            })
        }
        emailVerifyPopup.addButtons([continueButton, resendButton])
        return emailVerifyPopup
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
    

    private func addNewUserToDBJson(){
        let rating: Float = 5.0
        self.newUserUID = Auth.auth().currentUser?.uid
        let emailHash = MD5(string: self.emailTF.text!)
        let userDict:[String:Any] = ["uid":self.newUserUID, "name":"\(firstName!) \(lastName!)", "email":emailTF.text!, "rating":rating, "ratingSum":rating, "currentDevice":AppDelegate.DEVICEID]
        self.dbRef.child("Users/\(emailHash)").updateChildValues(userDict) { (error, databaseRef) in
            if let err = error{
                print(err.localizedDescription)
                return
            }
        }
    }
    
    private func presentVerifyEmailPopup(){
        self.present(self.emailPopup!, animated: true, completion: {
            self.loadingAnimation.stop()
            self.loadingAnimation.makeAnimationDissapear(tag: 2)
            self.continueButtonEmail.makeButtonAppear()
        })
    }
    
    private func errorAnimation(){
        self.emailCheckAnimation.makeAnimationDissapear(tag: 2)
        let errorEmail = self.view.returnHandledAnimation(filename: "error", subView: self.emailCheckAnimation, tagNum: 3)
        errorEmail.play()
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            self.emailCheckAnimation.makeAnimationDissapear(tag: 3)
            self.continueButtonEmail.makeButtonAppear()
        }
    }
    
    private func presentLoadingView(){
        self.loadingAnimation = self.view.returnHandledAnimation(filename: "loading", subView: self.emailCheckAnimation, tagNum: 2)
        self.continueButtonEmail.makeButtonDissapear()
        self.loadingAnimation.play()
        self.loadingAnimation.loopAnimation = true
    }

    private func addToDBAnimationAndSegue(){
        self.addNewUserToDBJson()
        self.emailCheckAnimation.handledAnimation(Animation: self.checkEmail)
        self.continueButtonEmail.makeButtonDissapear()
        self.checkEmail.play()
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            self.checkEmail.stop()
            self.performSegue(withIdentifier: "chooseProfilePicture", sender: self)
            
        }
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
