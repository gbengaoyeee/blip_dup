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
                row.tag = "address"
                row.title = "Street"
                row.placeholder = "Enter your Street address"
            }
            <<< TextRow(){ row in
                row.tag = "city"
                row.title = "City"
                row.placeholder = "Eg. Toronto"
            }
            <<< TextRow(){ row in
                row.tag = "postalCode"
                row.title = "Postal code"
                row.placeholder = "Eg. L5L6A2"
            }
            <<< TextRow(){ row in
                row.tag = "province"
                row.title = "Province"
                row.placeholder = "Eg. Ontario"
            }
        
        
        form +++ Section("Identity verification")
            <<< DateRow(){
                $0.tag = "date"
                $0.title = "Date of birth"
                $0.value = Date(timeIntervalSinceReferenceDate: 0)
            }
            <<< TextRow(){ row in
                row.tag = "sin"
                row.title = "SIN no."
                row.placeholder = "9 digit SIN number"
            }
        
        form +++ Section("Bank account deposits")
            <<< TextRow(){ row in
                row.tag = "routingNumber"
                row.title = "Routing number"
                row.placeholder = " eg. 0AAABBBBB"
            }
            <<< TextRow(){ row in
                row.tag = "accountNumber"
                row.title = "Account number"
                row.placeholder = "Chequing account number"
            }
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = "Done"
                $0.cell.backgroundColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
                $0.cell.tintColor = UIColor.white
                }
                .onCellSelection { cell, row in
                    
                    MyAPIClient.sharedClient.verifyStripeAccount(routingNumber: self.form.values()["routingNumber"] as! String, accountNumber: self.form.values()["accountNumber"] as! String, city: self.form.values()["city"] as! String, streetAdd: self.form.values()["address"] as! String, postalCode: self.form.values()["postalCode"] as! String, province: self.form.values()["province"] as! String, dobDay: "01", dobMonth: "05", dobYear: "1996", firstName: "Srikanth", lastName: "Srinivas", sin: self.form.values()["sin"] as! String, completion: { (json, error) in
                        if error == nil{
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
            }
    }
}

