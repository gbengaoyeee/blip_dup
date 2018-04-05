//
//  Lgsupage.swift
//  Blip
//
//  Created by Srikanth Srinivas on 7/29/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import AVFoundation
import Lottie
import FBSDKLoginKit
import FBSDKCoreKit
import Material
import Firebase
import RevealingSplashView


class Lgsupage: UIViewController {
    @IBOutlet weak var facebookLoginButton: RaisedButton!
    
    var Player: AVPlayer!
    var PlayerLayer: AVPlayerLayer!
    
    @IBOutlet var BlipLogo: UIView!
    @IBOutlet var BlipLabel: UILabel!
    @IBOutlet var LoginButton: UIButton!
    @IBOutlet var SignUpButton: UIButton!

    var dbRef: DatabaseReference!
    let logoAnimation = LOTAnimationView(name: "clock")
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        Player.play()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareFacebookButton()
        self.dbRef = Database.database().reference()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let hash = appDelegate.lastUserHash{
            self.dbRef.child("Users").child(hash).removeValue()
        }
        self.navigationController?.navigationBar.isHidden = true
        playLogoAnimation()
        playBackgroundVideo()
    }
    
    fileprivate func playLogoAnimation() {
        BlipLabel.adjustsFontSizeToFitWidth = true
        BlipLogo.handledAnimation(Animation: logoAnimation, width: 1, height: 1)
        logoAnimation.play()
    }
    
    
    fileprivate func prepareFacebookButton(){
        let facebookImage = UIImage(icon: .fontAwesome(.facebookF), size: CGSize(width: 40, height: 40), textColor: UIColor.white, backgroundColor: .clear)
        
        facebookLoginButton.image = facebookImage
        
    }
    
    fileprivate func playBackgroundVideo(){
        //Load video background
        let URL = Bundle.main.url(forResource: "lgsu", withExtension: "mp4")
        Player = AVPlayer.init(url: URL!)
        Player.allowsExternalPlayback = true
        Player.isMuted = true
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        Player.play()
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        let darkView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        darkView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        darkView.alpha = 0.5
        self.view.insertSubview(darkView, at: 1)
        
        NotificationCenter.default.addObserver(self,selector: #selector(appWillEnterForegroundNotification),name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
    }
    
    //Handle the swipes
    
    
    @IBAction func loginWithFacebookClicked(_ sender: Any) {
        
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self) { (result, error) -> Void in
            if (error == nil){
                let fbloginresult : FBSDKLoginManagerLoginResult = result!
                // if user cancel the login
                if (result?.isCancelled)!{
                    return
                }
                if(fbloginresult.grantedPermissions.contains("email"))
                {
                    self.getFBUserData()
                    self.userDefaults.removeObject(forKey: "loginCredentials")
                }
            }
        }
    }
    @objc func appWillEnterForegroundNotification() {
        Player.play()
    }

    @objc func playerItemReachEnd(notification:NSNotification){
        Player.seek(to:kCMTimeZero)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    //everything works
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    Auth.auth().signIn(with: credential) { (user, error) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                        
                        print("Signed in with Facebook")
                        let data = result as! [String: AnyObject]
                        let FBid = data["id"] as? String
                        let url = URL(string: "https://graph.facebook.com/\(FBid!)/picture?type=large&return_ssl_resources=1")
                        let profile = user?.createProfileChangeRequest()
                        profile?.photoURL = url
                        profile?.commitChanges(completion: { (err) in
                            if err != nil{
                                print(err?.localizedDescription ?? "")
                            }else{
                                let emailHash = self.MD5(string: (user?.email)!)
                                self.dbRef.child("Users").child(emailHash).child("photoURL").setValue(url?.absoluteString)
                            }
                        })
                        
                        self.addNewUserToDBJson(user: user!)
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.setLoginAsRoot()
                    }
                }
                else{
                    print(error?.localizedDescription ?? "")
                    return
                }
            })
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
    
    func addNewUserToDBJson(user: User){
        
        let rating: Float = 5.0
        let emailHash = MD5(string: user.email!)
        let token = ["currentDevice" : AppDelegate.DEVICEID]
        dbRef.child("Users").child(emailHash).child("uid").setValue(user.uid)
        dbRef.child("Users").child(emailHash).child("Name").setValue("\(user.displayName!)")
        dbRef.child("Users").child(emailHash).child("Email").setValue(user.email)
        dbRef.child("Users").child(emailHash).child("Rating").setValue(rating)
        dbRef.child("Users").child(emailHash).child("ratingSum").setValue(5.0)
        dbRef.child("Users").child(emailHash).updateChildValues(token)
    }
    
}



