//
//  EarningsVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-06-06.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material

class EarningsVC: UIViewController {

    @IBOutlet weak var earningsLabel: UILabel!
    @IBOutlet weak var depositDateLabel: UILabel!
    @IBOutlet weak var feedbackText: UITextView!
    @IBOutlet weak var goHomeButton: RaisedButton!
    
    var job: Job!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        prepareGoHomeButton()
    }
    
    func prepareGoHomeButton(){
        goHomeButton.setIcon(icon: .googleMaterialDesign(.check), iconSize: self.goHomeButton.frame.size.width, color: UIColor.white, backgroundColor: UIColor.clear, forState: .normal)
        goHomeButton.makeCircular()
    }
    
    func prepareLabels(){
        earningsLabel.text = "$ \(job.earnings)"
        depositDateLabel.text = "7 Days"
    }

    @IBAction func donePressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
