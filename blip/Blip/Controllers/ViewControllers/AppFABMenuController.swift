
import UIKit
import Material
import Firebase
import PopupDialog
import Kingfisher

class AppFABMenuController: FABMenuController{
    fileprivate let fabMenuSize = CGSize(width: 40, height: 40)
    fileprivate let bottomInset: CGFloat = 50
    fileprivate let rightInset: CGFloat = 20

    fileprivate var fabButton: FABButton!
    fileprivate var logoutItem: FABMenuItem!
    fileprivate var profilePageItem: FABMenuItem!
    fileprivate var privacyPolicy: FABMenuItem!

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
        preparePrivacy()
        prepareFABMenu()
    }
}

extension AppFABMenuController {
    fileprivate func prepareFABButton() {

        fabButton = FABButton()
        fabButton.pulseColor = .white
        fabButton.backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        fabButton.imageView?.makeCircular()
        fabButton.makeCircular()
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
        logoutItem.fabButton.backgroundColor = UIColor.red
        logoutItem.fabButton.addTarget(self, action: #selector(handleLogout(button:)), for: .touchUpInside)
    }
    
    fileprivate func preparePrivacy(){
        privacyPolicy = FABMenuItem()
        privacyPolicy.title = "Privacy Policy"
        privacyPolicy.fabButton.image = UIImage(icon: .googleMaterialDesign(.lock), size: CGSize(width: 40, height: 40), textColor: UIColor.white, backgroundColor: UIColor.clear)
        privacyPolicy.fabButton.tintColor = .white
        privacyPolicy.fabButton.pulseColor = .white
        privacyPolicy.fabButton.backgroundColor = UIColor.red
        privacyPolicy.fabButton.addTarget(self, action: #selector(handlePrivacy(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareProfilePageFabMenuItem(){
        profilePageItem = FABMenuItem()
        profilePageItem.title = "Verify Account"
        profilePageItem.fabButton.image = UIImage(icon: .googleMaterialDesign(.checkCircle), size: CGSize(width: 40, height: 40), textColor: UIColor.white, backgroundColor: UIColor.clear)
        profilePageItem.fabButton.tintColor = .white
        profilePageItem.fabButton.pulseColor = .white
        profilePageItem.fabButton.backgroundColor = UIColor.red
        profilePageItem.fabButton.addTarget(self, action: #selector(handleProfile(button:)), for: .touchUpInside)
    }


    fileprivate func prepareFABMenu() {
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [logoutItem, profilePageItem, privacyPolicy]
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
        let settingsPage = sb.instantiateViewController(withIdentifier: "settingsVC") as! SettingsVC
        self.present(settingsPage, animated: true, completion: nil)
    }

    @objc fileprivate func handlePrivacy(button: UIButton){
        fabMenu.fabButton?.animate(.rotate(0))
        fabMenu.close()
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let webVc = sb.instantiateViewController(withIdentifier: "webPrivacyPolicyVc")
        self.present(webVc, animated: true, completion: nil)
    }
    @objc fileprivate func handleLogout(button: UIButton) {
        fabMenu.close()
        fabMenu.fabButton?.animate(.rotate(0))
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
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

