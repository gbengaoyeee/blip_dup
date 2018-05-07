//
//  SettingsVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 5/6/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Kingfisher
import Hero
import Material
import Firebase
import FBSDKLoginKit
import PopupDialog

class SettingsVC: UIViewController {

    @IBOutlet weak var profilePictureView: UIImageView!
    
    var profilePicture: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareProfileImage()
    }
    
    func prepareProfileImage(){
        profilePictureView.makeCircular()
        profilePictureView.ApplyOuterShadowToView()
        profilePictureView.image = profilePicture
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func updateBankDetails(_ sender: Any) {
        
    }
    
    @IBAction func logout(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            let facebookLoginManager = FBSDKLoginManager()
            facebookLoginManager.logOut()
            print("Logged out")
        } catch let signOutError as NSError {
            let signOutErrorPopup = PopupDialog(title: "Error", message: "Error signing you out, try again later" + signOutError.localizedDescription )
            self.present(signOutErrorPopup, animated: true, completion: nil)
            print ("Error signing out: %@", signOutError)
        }
    }
}

