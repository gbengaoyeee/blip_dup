//
//  GroceryListViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-02-28.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Pastel
import Material
import Lottie
import WalmartOpenApi

class GroceryListViewController: UIViewController, TextViewDelegate {

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var groceryList: TextView!
    @IBOutlet weak var continueButton: RaisedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientView.prepareDefaultPastelView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let listOfItems = groceryList.text.components(separatedBy: ",")
    }
    
    @IBOutlet weak var continuePressed: RaisedButton!
    
}
