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
        "Alberta": "AB",
        "British Columbia": "BC",
        "Manitoba": "MB",
        "New Brunswick": "NB",
        "Newfoundland and Labrador": "NL",
        "Northwest Territories": "NT",
        "Nova Scotia": "NS",
        "Nunavut": "NU",
        "Ontario": "ON",
        "Prince Edward Island": "PE",
        "Quebec": "QC",
        "Saskatchewan": "SK",
        "Yukon": "YT"]
    
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
                    
                    if !self.validateSIN(SIN: self.form.values()["sin"] as? String){
                        //Invalid SIN
                        let popup = self.errorField(title: "Invalid SIN", message: "Please check your SIN Number and make sure it is correct")
                        self.present(popup, animated: true, completion: nil)
                        return
                    }
                    else if !self.validateAcctNo(acctNo: self.form.values()["accountNumber"] as? String){
                        //Invalid Account Number
                        let popup = self.errorField(title: "Invalid Account Number", message: "Please check your Account Number and make sure it is correct")
                        self.present(popup, animated: true, completion: nil)
                        return
                    }
                    else if !self.validateRoutingNumber(routingNumber: self.form.values()["routingNumber"] as? String){
                        //Invalid Routing Number
                        let popup = self.errorField(title: "Invalid Routing Number", message: "Please check your Routing Number and make sure it is correct")
                        self.present(popup, animated: true, completion: nil)
                        return
                    }
                    else if !self.validateProvince(province: self.form.values()["province"] as? String){
                        //Invalid province
                        let popup = self.errorField(title: "Invalid province", message: "Please check your province and make sure it is correct")
                        self.present(popup, animated: true, completion: nil)
                        return
                    }
                    
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day,.month,.year], from: self.form.values()["date"] as! Date)
                    if let day = components.day, let month = components.month, let year = components.year {
                        let dayString = String(day)
                        let monthString = String(month)
                        let yearString = String(year)
                        MyAPIClient.sharedClient.verifyStripeAccount(routingNumber: self.form.values()["routingNumber"] as! String, accountNumber: self.form.values()["accountNumber"] as! String, city: self.form.values()["city"] as! String, streetAdd: self.form.values()["address"] as! String, postalCode: self.form.values()["postalCode"] as! String, province: self.provinces[self.form.values()["province"] as! String], sin: self.form.values()["sin"] as! String, dobMonth: monthString, dobDay: dayString, dobYear: yearString, completion: { (json, error) in
                            if error == nil{
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
            }
    }
    
    
    func errorField(title:String, message:String)->PopupDialog{
        let popup = PopupDialog(title: title, message: message)
        return popup
    }
    
    
    ///* Validates a Routing Number
    fileprivate func validateRoutingNumber(routingNumber: String?)->Bool{
        if (routingNumber == nil){
            return false
        }
        if (routingNumber?.isEmpty)!{
            //Empty routing field
            return false
        }
        if ((routingNumber?.count)! < 9) || ((routingNumber?.count)! > 9){
            //Invalid Routing Number
            return false
        }
        var routingNumArr = [Int]()
        var ind = 0
        //populate array
        for i in routingNumber!{
            let num:Int = Int(String(i))!
            routingNumArr.append(num)
            ind += 1
        }
        //3(d_{0}+d_{3}+d_{6})+7(d_{1}+d_{4}+d_{7})+(d_{2}+d_{5}+d_{8})\mod 10=0.\,
        let firstSet:Int = 3 * (routingNumArr[0] + routingNumArr[3] + routingNumArr[6])
        let secondSet:Int = 7 * (routingNumArr[1] + routingNumArr[4] + routingNumArr[7])
        let thirdSet:Int = (routingNumArr[2] + routingNumArr[5] + routingNumArr[8])
        if ((firstSet+secondSet+thirdSet)%10) != 0{
            //Invalid Routing Number
            return false
        }
        return true
    }
    
    ///* Validates a Account Number
    fileprivate func validateAcctNo(acctNo:String?)->Bool{
        if (acctNo == nil){
            return false
        }
        if (acctNo?.isEmpty)!{
            //Invalid Account No
            return false
        }
        if ((acctNo?.count)! < 6) || ((acctNo?.count)! > 12){
            //Invalid Account No
            return false
        }
        return true
    }
    
    
    fileprivate func validateSIN(SIN: String?)->Bool{
        if (SIN == nil){
            return false
        }
        if (SIN?.isEmpty)!{
            //Invalid SIN
            return false
        }
        if ((SIN?.count)! < 9) || ((SIN?.count)! > 9){
            //Invalid SIN Number
            return false
        }
        var SIN_numArr = [Int]()
        var ind = 0
        var switchingNum:Int = 1
        //populate array
        for i in SIN!{
            let num:Int = Int(String(i))!
            let new_sin_num = num * switchingNum
            if switchingNum == 1{
                switchingNum = 2
            }
            else if switchingNum == 2{
                switchingNum = 1
            }
            if new_sin_num > 9{
                SIN_numArr.append(new_sin_num - 9)
            }else{
                SIN_numArr.append(new_sin_num)
            }
            ind += 1
            
        }
        let sum = SIN_numArr[0] + SIN_numArr[1] + SIN_numArr[2] + SIN_numArr[3] + SIN_numArr[4] + SIN_numArr[5] + SIN_numArr[6] + SIN_numArr[7] + SIN_numArr[8]
        if ((sum % 10) != 0){
            //Invalid SIN
            return false
        }
        return true
    }
    
    func validateProvince(province: String?) -> Bool{
        if province == nil{
            return false
        }
        if self.provinces[(province?.capitalized)!] == nil{
            return false
        }
        return true
    }
    
}







