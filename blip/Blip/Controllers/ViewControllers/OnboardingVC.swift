//
//  OnboardingVCViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-01-08.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Lottie
import Pastel
import CHIPageControl
import CoreLocation
import PopupDialog

class OnboardingVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var pageControl: CHIPageControlFresno!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var serviceAnimationView: UIView!

    var locationManager = CLLocationManager()
    let serviceAnimation = LOTAnimationView(name: "onboarding")
    let serviceArray = ["Welcome to Blip, the worlds first marketplace for free time","Take delivery jobs from around your location","Choose the type of delivery you'd be willing to make","Get paid instantaneously, turning your free time into cash","Hit get started to begin with a free account"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientView.animationDuration = 3.0
        gradientView.prepareDefaultPastelView()
        self.navigationController?.navigationBar.isHidden = true
        prepareAnimation()
        setupScrollView()
        pageControl.numberOfPages = 5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        gradientView.startAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        gradientView.startAnimation()
    }
    
    func setupScrollView(){
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: self.view.frame.size.width * 5, height: scrollView.frame.size.height)
        scrollView.showsHorizontalScrollIndicator = false
        for stage in 0...4{
            let label = UILabel(frame: CGRect(x: scrollView.center.x + CGFloat(stage) * self.view.frame.size.width - 125 , y: 0, width: 250, height: self.scrollView.frame.size.height))
            label.font = UIFont(name: "CenturyGothic", size: 20)
            label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            label.textAlignment = .center
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.text = serviceArray[stage]
            scrollView.addSubview(label)
        }
    }
    
    @IBAction func GoToLGSU(_ sender: Any) {
        useCurrentLocations()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let progress = scrollView.contentOffset.x  / self.scrollView.contentSize.width * 1.08
        serviceAnimation.animationProgress = progress
        let pageProgress = scrollView.contentOffset.x / self.view.frame.size.width
        print(progress)
        pageControl.progress = Double(pageProgress)
    }
    
    func prepareAnimation(){
        serviceAnimationView.handledAnimation(Animation: serviceAnimation, width: 1.3, height: 1.3)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension OnboardingVC: CLLocationManagerDelegate{
    
    func useCurrentLocations(){
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                let locationError = PopupDialog(title: "Location permission denied", message: "blip needs permission to access your location information, or we cannot match you with jobs around your area. Please go to settings; Privacy; Location services; and turn on location services for blip")
                self.present(locationError, animated: true, completion: nil)
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                self.performSegue(withIdentifier: "goToLGSU", sender: self)
            }
        }
    }
}
