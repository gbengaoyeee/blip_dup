//
//  EarningsVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-06-06.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material
import Lottie

class EarningsVC: UIViewController {

    @IBOutlet weak var earningsLabel: UILabel!
    @IBOutlet weak var depositDateLabel: UILabel!
    @IBOutlet weak var goHomeButton: RaisedButton!
    @IBOutlet weak var checkView: UIView!
    
    var job: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareLabels()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        prepareCheckView()
    }
    
    override func viewWillLayoutSubviews() {
        prepareGoHomeButton()
    }
    
    func prepareGoHomeButton(){
        goHomeButton.setIcon(icon: .googleMaterialDesign(.arrowForward), iconSize: (0.5*self.goHomeButton.frame.size.width), color: UIColor.white, backgroundColor: #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), forState: .normal)
        goHomeButton.makeCircular()
    }
    
    func prepareCheckView(){
        let check = LOTAnimationView(name: "checkmark")
        checkView.handledAnimation(Animation: check, width: 2.0, height: 2.0)
        check.play()
    }
    
    func prepareLabels(){
        let earnings = Double(job.earnings)
        let text = String(format: "%.2f", arguments: [earnings])
        earningsLabel.text = "$ \(text)"
        depositDateLabel.text = "7 Days"
    }

    @IBAction func donePressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
