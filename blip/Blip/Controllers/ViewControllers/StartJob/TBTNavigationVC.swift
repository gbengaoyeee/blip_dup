//
//  TBTNavigationVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-02-02.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation
import Kingfisher
import PopupDialog
import Firebase
import Alamofire

class TBTNavigationVC: NavigationViewController, NavigationViewControllerDelegate, CLLocationManagerDelegate {
    var job: Job!
    var locationManager = CLLocationManager()
    let service = ServiceCalls()
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        useCurrentLocations()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateAccepterLocation), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func useCurrentLocations(){
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let startActualJobVC = sb.instantiateViewController(withIdentifier: "endJobNavigation") as? endJobNavigation
        if let job = self.job{
            startActualJobVC?.job = job
        }
        
        self.locationManager.stopUpdatingLocation()
        self.timer.invalidate()
        
        self.present(startActualJobVC!, animated: true, completion: nil)
        return true
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    
    @objc func updateAccepterLocation(){
        
        print("updating accepter location")
        if let location = self.locationManager.location?.coordinate{
            service.updateJobAccepterLocation(location: location)
        }
    }

}
