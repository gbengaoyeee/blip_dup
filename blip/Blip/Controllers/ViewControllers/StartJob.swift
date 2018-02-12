//
//  endJobNavigation.swift
//  Blip
//
//  Created by Srikanth Srinivas on 1/28/18.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Pastel
import Firebase
import Kingfisher
import Material
import PopupDialog
import Alamofire

class StartJob: UIViewController {

    var job: Job!
    
    @IBOutlet weak var jobView: UIView!
    @IBOutlet weak var gradientView: PastelView!
    let service = ServiceCalls()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.jobView.ApplyOuterShadowToView()
        gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
        let jobViewFromNib = Bundle.main.loadNibNamed("PopUpJobView", owner: self, options: nil)?.first as! PopUpJobViewVC
        jobViewFromNib.setJob(job: self.job)
        jobViewFromNib.setupScrollView(job: self.job)
        jobViewFromNib.setupScrollView(job: self.job)
        self.jobView.addSubview(jobViewFromNib)
    }

    override func viewDidAppear(_ animated: Bool) {
        
        goToEndJob()
        self.gradientView.startAnimation()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.gradientView.startAnimation()
    }
    
    @IBAction func startJobPressed(_ sender: Any) {
        
        let awaitingPosterConfirmation = PopupDialog(title: "Please wait", message: "\(self.job.jobOwnerFullName!) has been notified. The job will begin once the poster confirms")
        self.present(awaitingPosterConfirmation, animated: true) {
            self.service.accepterReady(job: self.job, completion: { (ownerDeviceToken) in
                //Send notification to owner
                let title = "Blip"
                let displayName = (Auth.auth().currentUser?.displayName)!
                let body = "\(displayName) is ready to begin your task"
                let device = ownerDeviceToken!
                var headers: HTTPHeaders = HTTPHeaders()
                headers = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
                
                let notification = ["to":"\(device)", "notification":["body":body, "title":title, "badge":1, "sound":"default"]] as [String : Any]
                
                Alamofire.request(AppDelegate.NOTIFICATION_URL as URLConvertible, method: .post as HTTPMethod, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in
                    
                    if let err = response.error{
                        print(err.localizedDescription)
                    }
                })
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "accepterReadyNotification"), object: nil)
            })
        }
        
    }
    
    func goToEndJob(){
    
        service.setAppState(completion: { (code, job) in
            
            
            if code == 2{
                
                let sb = UIStoryboard.init(name: "Main", bundle: nil)
                let completeJob = sb.instantiateViewController(withIdentifier: "endJob") as? EndJob
                completeJob?.job = self.job
                self.present(completeJob!, animated: true, completion: nil)
            }
        })
    }
    
    
    
}
