//
//  ChoosePictureVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-03.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material
import Pastel
import Lottie

class ChoosePictureVC: UIViewController {

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var cameraAnimationView: UIView!
    @IBOutlet weak var goButton: RaisedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        prepareGradientView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        prepareGradientView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        prepareCameraAnimation()
    }
    
    fileprivate func prepareGradientView(){
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }
    
    
    fileprivate func prepareCameraAnimation(){
        let cameraAnimation = LOTAnimationView(name: "camera")
        cameraAnimationView.handledAnimation(Animation: cameraAnimation, width: 2, height: 2)
        cameraAnimation.play()
    }
}
