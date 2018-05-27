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
import Alamofire


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
    var service:ServiceCalls! = ServiceCalls.instance
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareFacebookButton()
        self.dbRef = Database.database().reference()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let hash = appDelegate.lastUserHash{
            self.dbRef.child("Couriers").child(hash).removeValue()
        }
        self.navigationController?.navigationBar.isHidden = true
        playLogoAnimation()
        playBackgroundVideo()
    }
    
    
    ///To be gotten rid of
    fileprivate func playLogoAnimation() {
        BlipLabel.adjustsFontSizeToFitWidth = true
        BlipLogo.handledAnimation(Animation: logoAnimation, width: 1, height: 1)
        logoAnimation.play()
    }
    
    ///Prepares the "Login wiith Facebook" button
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

    /**
     Logs in user with facebook
     */
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
                    self.service.getFBUserData(completion: { (email, firstName, lastName) in
                        guard let email = email, let firstName = firstName, let lastName = lastName else{
                            print("Facebook got weird")
                            return
                        }
                        MyAPIClient.sharedClient.createNewStripeAccount(email: email, firstName: firstName, lastName: lastName, completion: { (responseVal, error) in
                            if let error = error as? AFError{
                                print(error.errorDescription!)
                                return
                            }
                            print("RESPONSE VALUE", responseVal)
                        })
                    })
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

