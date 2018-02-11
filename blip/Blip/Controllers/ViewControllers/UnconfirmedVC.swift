////
////  UnconfirmedVC.swift
////  Blip
////
////  Created by Gbenga Ayobami on 2017-10-28.
////  Copyright © 2017 Gbenga Ayobami. All rights reserved.
////
//
//import UIKit
//import Firebase
//
//class UnconfirmedVC: UITableViewController {
//    
//    let service = ServiceCalls()
//    var unconfirmedLst: [Job]!
//    var selectedJob: Job!
//    var applicantsEHashDict:[String:String] = [:]
//    
//    let cardHeight: CGFloat = 600
//    let cardWidth: CGFloat = 300
//    var yPosition:CGFloat = 0
//    var scrollViewContentSize: CGFloat = 0
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.navigationController?.navigationBar.isHidden = false
//    }
//    
//
//    
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        
//        return self.unconfirmedLst.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        cell.textLabel?.text = self.unconfirmedLst[indexPath.row].title
//        return cell
//    }
//
////    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
////        selectedJob = unconfirmedLst[indexPath.row]
////        self.service.getApplicants(job: self.selectedJob) { (applicantsDict) in
////            self.applicantsEHashDict = applicantsDict
////            self.performSegue(withIdentifier: "goToApplicants", sender: nil)
////        }
////    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "goToApplicants"{
//            if let dest = segue.destination as? ApplicantsVC{
//                dest.applicantsDict = self.applicantsEHashDict
//            }
//        }
//    }
//}
//extension UnconfirmedVC{
//    
//    
//    //    func resetCardAttributesValues(){
//    //        yPosition = 0
//    //        scrollViewContentSize = 0
//    //    }
//    
//    //    func loadAndAddCardToScrollView(job: Job){
//    //
//    //        var popupCard: PopUpJobViewVC!
//    //        popupCard = Bundle.main.loadNibNamed("PopUpJobView", owner: nil, options: nil)?.first as! PopUpJobViewVC
//    //
//    //        popupCard.job = job
//    //
//    //
//    //        popupCard.fullNameLabel.ApplyCornerRadiusToView()
//    //        popupCard.jobDescriptionLabel.ApplyCornerRadiusToView()
//    //        popupCard.priceLabel.ApplyCornerRadiusToView()
//    //        popupCard.ApplyCornerRadiusToView()
//    //        popupCard.ApplyOuterShadowToView()
//    //
//    //
//    //        popupCard.fullNameLabel.text = job.jobOwnerFullName
//    //        popupCard.jobDescriptionLabel.text = job.description
//    //        popupCard.priceLabel.text = ("$"+"\(job.wage_per_hour)"+"/Hour")
//    //        popupCard.acceptButton.isHidden = true
//    //
//    //        let animation = popupCard.returnHandledAnimation(filename: "5_stars", subView: popupCard.rating, tagNum: 1)
//    //        animation.play()
//    //
//    //        popupCard.center = self.view.center
//    //        popupCard.frame.origin.y = yPosition
//    //
//    //
//    //        self.scrollView.addSubview(popupCard)
//    //        let spacer: CGFloat = 20
//    //
//    //        yPosition = yPosition + cardHeight + spacer
//    //        scrollViewContentSize = scrollViewContentSize + cardHeight + spacer
//    //
//    //        self.scrollView.contentSize = CGSize(width: cardWidth, height: scrollViewContentSize)
//    //
//    //
//    //    }
//}

