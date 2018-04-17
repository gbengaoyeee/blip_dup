//
//  WaypointArrivalVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 4/14/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Lottie
import MapboxNavigation
import MapboxDirections
import Mapbox
import Material

class WaypointArrivalVC: UIViewController {

    @IBOutlet weak var doneButton: RaisedButton!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    
    var delivery: Delivery!
    var waypoint: BlipWaypoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMap()
        print(delivery.recieverName)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func prepareMap(){
        map.makeCircular()
        map.clipsToBounds = true
        map.ApplyOuterShadowToView()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
