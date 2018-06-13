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
import Material
import Firebase
import RevealingSplashView
import Alamofire

class Lgsupage: UIViewController {
    
    var Player: AVPlayer!
    var PlayerLayer: AVPlayerLayer!
    
    @IBOutlet var LoginButton: UIButton!

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
        self.dbRef = Database.database().reference()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let hash = appDelegate.lastUserHash{
            self.dbRef.child("Couriers").child(hash).removeValue()
        }
        self.navigationController?.navigationBar.isHidden = true
        playBackgroundVideo()
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let webVc = sb.instantiateViewController(withIdentifier: "webSignUpVc")
        self.present(webVc, animated: true, completion: nil)
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

