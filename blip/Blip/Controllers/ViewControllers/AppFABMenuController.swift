
import UIKit
import Material
import Firebase
import FBSDKLoginKit
import Stripe
import PopupDialog
import Kingfisher

class AppFABMenuController: FABMenuController{
    fileprivate let fabMenuSize = CGSize(width: 40, height: 40)
    fileprivate let bottomInset: CGFloat = 50
    fileprivate let rightInset: CGFloat = 20
    
    fileprivate var fabButton: FABButton!
    fileprivate var logoutItem: FABMenuItem!
    fileprivate var unconfirmedItem: FABMenuItem!
    fileprivate var profilePageItem: FABMenuItem!
    
    var currUser: BlipUser?
    let service = ServiceCalls.instance
    let userDefaults = UserDefaults.standard
    var userCredDict:[String:String]!
    let loginCredentials = "loginCredentials"
    
    open override func prepare() {
        super.prepare()
        view.backgroundColor = .white
        prepareFABButton()
        prepareLogoutFabMenuItem()
        prepareProfilePageFabMenuItem()
        prepareFABMenu()
    }
}

extension AppFABMenuController {
    fileprivate func prepareFABButton() {
        
        fabButton = FABButton()
        fabButton.pulseColor = .white
        fabButton.backgroundColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
        fabButton.imageView?.makeCircular()
        fabButton.makeCircular()
        fabButton.setIcon(icon: .googleMaterialDesign(.settings), color: UIColor.white, forState: .normal)
        self.setImageToButton()
        
    }
    
    func setImageToButton(){
        if let url = Auth.auth().currentUser?.photoURL{
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { (image, error, type, url) in
                if let image = image {
                    self.fabButton.setImage(image, for: .normal)
                    self.fabButton.clipsToBounds = true
                }
            }
        }
        else{
            self.fabButton.setIcon(icon: .googleMaterialDesign(.settings), iconSize: 40, color: UIColor.white, forState: .normal)
        }
    }
    
    fileprivate func prepareLogoutFabMenuItem() {
        logoutItem = FABMenuItem()
        logoutItem.title = "Logout"
        logoutItem.fabButton.image = Icon.cm.clear
        logoutItem.fabButton.tintColor = .white
        logoutItem.fabButton.pulseColor = .white
        logoutItem.fabButton.backgroundColor = Color.blue.base
        logoutItem.fabButton.addTarget(self, action: #selector(handleLogout(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareProfilePageFabMenuItem(){
        profilePageItem = FABMenuItem()
        profilePageItem.title = "Profile"
        profilePageItem.fabButton.image = Icon.cm.image
        profilePageItem.fabButton.tintColor = .white
        profilePageItem.fabButton.pulseColor = .white
        profilePageItem.fabButton.backgroundColor = Color.blue.base
        profilePageItem.fabButton.addTarget(self, action: #selector(handleProfile(button:)), for: .touchUpInside)
    }
    

    fileprivate func prepareFABMenu() {
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [logoutItem, profilePageItem]
        fabMenuBacking = .none
        fabMenu.fabMenuDirection = .down
        view.layout(fabMenu)
            .top(bottomInset)
            .right(rightInset)
            .size(fabMenuSize)
    }
}

extension AppFABMenuController {
    @objc fileprivate func handleProfile(button: UIButton){
        fabMenu.fabButton?.animate(.rotate(0))
        fabMenu.close()
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let settingsPage = sb.instantiateViewController(withIdentifier: "settings") as! SettingsVC
        self.present(settingsPage, animated: true, completion: nil)

    }
    
    @objc fileprivate func handleLogout(button: UIButton) {
        fabMenu.close()
        fabMenu.fabButton?.animate(.rotate(0))
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

extension AppFABMenuController {
    @objc open func fabMenuWillOpen(fabMenu: FABMenu) {
        fabMenu.fabButton?.animate(.rotate(0))
        print("fabMenuWillOpen")
    }
    
    @objc open func fabMenuDidOpen(fabMenu: FABMenu) {
        print("fabMenuDidOpen")
    }
    
    @objc open func fabMenuWillClose(fabMenu: FABMenu) {
        fabMenu.fabButton?.animate(.rotate(0))
        print("fabMenuWillClose")
    }
    
    @objc open func fabMenuDidClose(fabMenu: FABMenu) {
        print("fabMenuDidClose")
    }
}

