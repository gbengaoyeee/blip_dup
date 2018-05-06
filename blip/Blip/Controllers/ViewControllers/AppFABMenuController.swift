
import UIKit
import Material
import Firebase
import FBSDKLoginKit
import Stripe
import PopupDialog
import Kingfisher

class AppFABMenuController: FABMenuController, STPPaymentContextDelegate{
    fileprivate let fabMenuSize = CGSize(width: 40, height: 40)
    fileprivate let bottomInset: CGFloat = 50
    fileprivate let rightInset: CGFloat = 20
    
    fileprivate var fabButton: FABButton!
    fileprivate var logoutItem: FABMenuItem!
    fileprivate var unconfirmedItem: FABMenuItem!
    fileprivate var paymentMethodsItem: FABMenuItem!
    fileprivate var profilePageItem: FABMenuItem!
    var paymentContext: STPPaymentContext? = nil
    
    var currUser: BlipUser?
    let service = ServiceCalls.instance
    let userDefaults = UserDefaults.standard
    
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print(error)
        
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        let source = paymentResult.source.stripeID
        MyAPIClient.sharedClient.addPaymentSource(id: source, completion: { (error) in })
    }
    
    open override func prepare() {
        super.prepare()
        view.backgroundColor = .white
        prepareFABButton()
        prepareLogoutFabMenuItem()
        prepareProfilePageFabMenuItem()
        preparePaymentMethodsItem()
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
        // Not good way to do it
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            self.setImageToButton()
        })
    }
    
    func setImageToButton(){
        if self.fabButton.image == nil{
            if let credentials = userDefaults.dictionary(forKey: "loginCredentials"){
                print(credentials)
                if let pictureString = credentials["photoURL"] as? String{
                    KingfisherManager.shared.retrieveImage(with: URL(string: pictureString)!, options: nil, progressBlock: nil) { (image, error, type, url) in
                        if let image = image {
                            self.fabButton.setImage(image, for: .normal)
                            self.fabButton.clipsToBounds = true
                        }
                    }
                }
            }
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
    
    fileprivate func preparePaymentMethodsItem() {
        paymentMethodsItem = FABMenuItem()
        paymentMethodsItem.title = "Payment Methods"
        paymentMethodsItem.fabButton.image = Icon.cm.settings
        paymentMethodsItem.fabButton.tintColor = .white
        paymentMethodsItem.fabButton.pulseColor = .white
        paymentMethodsItem.fabButton.backgroundColor = Color.blue.base
        paymentMethodsItem.fabButton.addTarget(self, action: #selector(handlePaymentMethods(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareFABMenu() {
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [logoutItem, paymentMethodsItem, profilePageItem]
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
        if let profilepage = sb.instantiateViewController(withIdentifier: "profilePage") as? ProfilePage{
            profilepage.currUser = currUser
            self.present(profilepage, animated: true, completion: nil)
        }else{
            print("Something is Wrong: No profile page")
        }
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
    
    @objc fileprivate func handlePaymentMethods(button: UIButton) {
        self.paymentContext = STPPaymentContext(apiAdapter: CustomAPIAdapter())
        self.paymentContext!.delegate = self
        self.paymentContext!.hostViewController = self
        self.paymentContext!.presentPaymentMethodsViewController()
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

