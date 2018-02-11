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

class PopUpJobViewVC: UIView, CLLocationManagerDelegate {
    

    @IBOutlet weak var jobDescription: UILabel!
    @IBOutlet weak var jobTitle: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var job: Job!
    private let service: ServiceCalls = ServiceCalls()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setJob(job: Job){
        self.job = job
        self.fullNameLabel.text = job.jobOwnerFullName
    }
    
    func getProfilePicture(job: Job){
        
        service.getUserInfo(hash: job.jobOwnerEmailHash) { (user) in
            self.profilePicture.cornerRadius = self.profilePicture.frame.size.height/2
            self.profilePicture.kf.setImage(with: user?.photoURL)
        }
    }
    
    func setupScrollView(job: Job){
        
        self.jobTitle.text = job.title
        self.jobDescription.text = job.description
    }

}



