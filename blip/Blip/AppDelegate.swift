//
//  AppDelegate.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-02-10.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Firebase
import Material
import UserNotifications
import Stripe
import RevealingSplashView
import PopupDialog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate{

    var connectivity = Connectivity()
    var lastUserHash: String!
    var dbRef:DatabaseReference!{
        return Database.database().reference()
    }
    var isLaunched = false
    var window: UIWindow?
    var sessionTimer: Timer!
    var isWaiting = false

    var counter = 60
    static let NOTIFICATION_URL = "https://fcm.googleapis.com/fcm/send"
    static var DEVICEID = String()
    static let SERVERKEY = "AAAAzHCGqik:APA91bGDGsKKvtlaTgbVsLtRnUrWs00wXc9aWNBBoEcbZ8TUQiclkCe4RpUzMxGx2m0jvwnLaTBG-Jwc-57qFE0F-QFmRNaBzPfGsIQj5LSEUvnlzA8kQu6pwJuCPfI2iCzO191eHoY-"

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        isLaunched = true
        
        STPPaymentConfiguration.shared().publishableKey = "pk_test_K45gbx2IXkVSg4pfmoq9SIa9"
        STPPaymentConfiguration.shared().appleMerchantIdentifier = "merchant.online.intima"
        
        _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if auth.currentUser != nil {
                self.setLoginAsRoot()
            }
            else{
                self.setLogoutAsRoot()
            }
        }
        
        if #available(iOS 10.0, *){
            UNUserNotificationCenter.current().delegate = self
            let option : UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: option, completionHandler: { (bool, error) in
                
            })
        }else{
            let settings : UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        //check for connectivity
        connectivity?.whenReachable = {_ in
            DispatchQueue.main.async {
                print("GOT INTERNET WHEN IT STARTED")
            }
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
        
        return true
    }
    
    
    @objc fileprivate func checkUserAgainstDatabase(completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        guard let currentUser = Auth.auth().currentUser else { return }
        currentUser.getIDTokenForcingRefresh(true) { (idToken, error) in
            if let error = error {
                completion(false, error as NSError?)
                print(error.localizedDescription)
                self.setLogoutAsRoot()
            } else {
                completion(true, nil)
            }
        }
    }
    
    fileprivate func goHome(){
        window = UIWindow(frame: Screen.bounds)
        window!.rootViewController = AppFABMenuController(rootViewController: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "rootAfterLogin"))
        window?.makeKeyAndVisible()
    }
    
    func setLogoutAsRoot(){
        if sessionTimer != nil{
            self.sessionTimer.invalidate()
        }
        window = UIWindow(frame: Screen.bounds)
        var options = UIWindow.TransitionOptions()
        options.direction = .fade
        options.duration = 0.8
        options.style = .easeOut
        window!.setRootViewController((UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "rootViewController")), options: options)
        window?.makeKeyAndVisible()
    }
    
    func setLoginAsRoot(){
        var options = UIWindow.TransitionOptions()
        options.direction = .fade
        options.duration = 0
        options.style = .easeIn
        self.window = UIWindow(frame: Screen.bounds)
        self.window!.setRootViewController(UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "rootAfterLogin"), options: options)
        self.window?.makeKeyAndVisible()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
    }

    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        guard let newToken = InstanceID.instanceID().token() else{return}
        AppDelegate.DEVICEID = newToken
        connectToFCM()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notification = response.notification.request.content.body
        
        print(notification)
        
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        guard let token = InstanceID.instanceID().token() else{return}
        
        AppDelegate.DEVICEID = token
        connectToFCM()
    }
    
    func connectToFCM(){
        Messaging.messaging().shouldEstablishDirectChannel = true
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
    
    @objc func connectivityChanged(notification: Notification){
        let connectivity = notification.object as! Connectivity
        if (connectivity.connection == .wifi || connectivity.connection == .cellular){
            print("REGAINED CONNECTION")
        }else{
            print("Connection Gone")
        }
    }

}

