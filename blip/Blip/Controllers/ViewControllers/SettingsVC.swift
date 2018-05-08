//
//  SettingsVC.swift
//  Blip
//
//  Created by Srikanth Srinivas on 5/6/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Kingfisher
import Hero
import Material
import Firebase
import FBSDKLoginKit
import PopupDialog
import Eureka

class SettingsVC: FormViewController {

    let provinces = [
        "Alberta",
        "British Columbia",
        "Manitoba",
        "New Brunswick",
        "Newfoundland and Labrador",
        "Northwest Territories",
        "Nova Scotia",
        "Nunavut",
        "Ontario",
        "Prince Edward Island",
        "Quebec",
        "Saskatchewan",
        "Yukon"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildForm()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func buildForm(){
        form +++ Section("Address")
            <<< TextRow(){ row in
                row.title = "Street"
                row.placeholder = "Enter your Street address"
            }
            <<< TextRow(){ row in
                row.title = "City"
                row.placeholder = "Eg. Toronto"
            }
            <<< TextRow(){ row in
                row.title = "Postal code"
                row.placeholder = "Eg. L5L6A2"
            }
        form +++ SelectableSection<ListCheckRow<String>>("Select a province", selectionType: .singleSelection(enableDeselection: false))
        for option in provinces {
            form.last! <<< ListCheckRow<String>(option){ listRow in
                listRow.title = option
                listRow.selectableValue = option
                listRow.value = nil
            }
        }
        form +++ Section("Identity verification")
            <<< DateRow(){
                $0.title = "Date of birth"
                $0.value = Date(timeIntervalSinceReferenceDate: 0)
            }
            <<< TextRow(){ row in
                row.title = "Social insurance number"
                row.placeholder = "Your data is used for KYC in connecting your bank account"
            }
    }
}

