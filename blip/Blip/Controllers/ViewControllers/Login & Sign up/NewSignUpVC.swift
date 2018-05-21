//
//  NewSignUpVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-03.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material
import Pastel
import PopupDialog
import SwiftIcons

class NewSignUpVC: UIViewController {

    @IBOutlet weak var signUpInfoLabel: UILabel!
    @IBOutlet weak var passwordLeading: NSLayoutConstraint!
    @IBOutlet weak var emailLeading: NSLayoutConstraint!
    @IBOutlet weak var lastnameLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstnameLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet weak var passwordTF: TextField!
    @IBOutlet weak var emailTF: TextField!
    @IBOutlet weak var lastNameTF: TextField!
    @IBOutlet weak var firstNameTF: TextField!
    @IBOutlet var gradientView: PastelView!
    var correctLeadingConstraint: CGFloat!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        setupGoButton()
        setupTF(tf: firstNameTF, title: "First Name")
        setupTF(tf: lastNameTF, title: "Last Name")
        setupTF(tf: emailTF, title: "Email")
        setupTF(tf: passwordTF, title: "Password")
        self.hideKeyboardWhenTappedAround()
        setupProperConstraints()
        setupGradientView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupGradientView()
    }
    
    fileprivate func setupGradientView(){
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }
    
    fileprivate func setupProperConstraints(){
        firstnameLeadingConstraint.constant = (self.view.frame.size.width - 220)/2
        correctLeadingConstraint = firstnameLeadingConstraint.constant
        lastnameLeadingConstraint.constant = correctLeadingConstraint
    }
    
    ///Setup TextFields
    fileprivate func setupTF(tf: TextField, title: String){
        
        tf.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        tf.font = UIFont(name: "Century Gothic", size: 17)
        tf.textColor = UIColor.white
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholder = title
        tf.placeholderActiveColor = UIColor.white
        tf.placeholderNormalColor = UIColor.white
        tf.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    fileprivate func setupGoButton(){
        goButton.layer.cornerRadius = goButton.frame.size.height/2
        goButton.backgroundColor = UIColor.white
        goButton.setIcon(icon: .googleMaterialDesign(.arrowForward), iconSize: 30, color: #colorLiteral(red: 0, green: 0.8495121598, blue: 0, alpha: 1), backgroundColor: UIColor.white, forState: .normal)
        
        //add functionality to the button
        goButton.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
    }

    @objc fileprivate func handleContinueButton(){
        let isTextfieldsEmpty = firstNameTF.isEmpty && lastNameTF.isEmpty && emailTF.isEmpty && passwordTF.isEmpty
        
        if (isTextfieldsEmpty){// there is empty field(s)
            self.present(popupForEmptyField(), animated: true, completion: nil)
        }
            
        else if firstNameTF.isEmpty || lastNameTF.isEmpty{
            self.present(popupForEmptyField(), animated: true, completion: nil)
        }
            
        else if !firstNameTF.isEmpty && !lastNameTF.isEmpty && emailTF.isEmpty && passwordTF.isEmpty{
            signUpInfoLabel.text = "We require a valid email address to verify your account. Your information will not be shared with any third party"
            UIView.animate(withDuration: 1) {
                self.firstnameLeadingConstraint.constant = -230
                self.lastnameLeadingConstraint.constant = -230
                self.emailLeading.constant = self.correctLeadingConstraint
                self.passwordLeading.constant = self.correctLeadingConstraint
                self.view.layoutIfNeeded()
            }
        }
        else if !firstNameTF.isEmpty && !lastNameTF.isEmpty && !emailTF.isEmpty && !passwordTF.isEmpty{
            if validateEmail(enteredEmail: emailTF.text!){
                self.performSegue(withIdentifier: "choosePicture", sender: nil)
            }
            else{
                self.present(popupForInvalidEmail(), animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func nextOnLastName(_ sender: Any) {
        if firstNameTF.isEmpty || lastNameTF.isEmpty{
            self.present(popupForEmptyField(), animated: true, completion: nil)
        }
            
        else{
            signUpInfoLabel.text = "We require a valid email address to verify your account. Your information will not be shared with any third party"
            UIView.animate(withDuration: 1) {
                self.firstnameLeadingConstraint.constant = -230
                self.lastnameLeadingConstraint.constant = -230
                self.emailLeading.constant = self.correctLeadingConstraint
                self.passwordLeading.constant = self.correctLeadingConstraint
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func nextOnPassword(_ sender: Any) {
        if !firstNameTF.isEmpty && !lastNameTF.isEmpty && !emailTF.isEmpty && !passwordTF.isEmpty{
            if validateEmail(enteredEmail: emailTF.text!){
                self.performSegue(withIdentifier: "choosePicture", sender: nil)
            }
            else{
                self.present(popupForInvalidEmail(), animated: true, completion: nil)
            }
        }
    }
    
    ///Sends the textfield information to the choose profile VC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "choosePicture"{
            let userInfoDict = ["name":"\(self.firstNameTF.text!) \(self.lastNameTF.text!)", "firstName":"\(self.firstNameTF.text!)", "lastName":"\(self.lastNameTF.text!)", "email":self.emailTF.text!, "password":self.passwordTF.text!]
            let destination = segue.destination as! ChoosePictureVC
            destination.userInfoDict = userInfoDict
        }
    }

    
    fileprivate func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    fileprivate func validatePassword(enteredPassword:String) ->Bool{
        let passwordFormat = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z !@#$%^&*()_\\-+={}\\[\\]\\\\|'\";:?\\/.,<>`~\\d]{6,}"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordFormat)
        return passwordPredicate.evaluate(with: enteredPassword)
    }
    
    fileprivate func popupForEmptyField()-> PopupDialog {
        let title = "Empty fields"
        let message = "Please enter required information inside all fields"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
    fileprivate func popupForInvalidEmail()-> PopupDialog {
        let title = "Invalid email"
        let message = "Please enter a valid email"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
    fileprivate func popupForInvalidPassword()-> PopupDialog {
        let title = "Invalid password"
        let message = "Your password must be at least six characters long and must contain at least one uppercase, at least one lowercase, and at least one number"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
}

extension UIColor{
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat){
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
