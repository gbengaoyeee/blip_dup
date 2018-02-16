//
//  PopUpJobViewVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 10/10/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Lottie
import MapKit
import Firebase
import Alamofire
import Material
import Kingfisher

class PopUpJobViewVC: UIViewController {
    

    @IBOutlet weak var jobDescription: UILabel!
    @IBOutlet weak var jobTitle: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var job: Job!
    private let service: ServiceCalls = ServiceCalls()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareNib()
    }
    
    func prepareNib(){
        
        self.jobTitle.text = job.title
        self.jobDescription.text = job.description
        self.fullNameLabel.text = job.jobOwnerFullName
        service.getUserInfo(hash: job.jobOwnerEmailHash) { (user) in
            self.profilePicture.cornerRadius = self.profilePicture.frame.size.height/2
            self.profilePicture.kf.setImage(with: user?.photoURL)
        }
    }

}



