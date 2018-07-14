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

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var firstNameTF: TextField!
    @IBOutlet weak var lastNameTF: TextField!
    @IBOutlet weak var emailTF: TextField!
    @IBOutlet weak var passwordTF: TextField!
    @IBOutlet weak var phoneNumberTf: TextField!
    @IBOutlet weak var goButton: RaisedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        setupGoButton()
        setupTF(tf: firstNameTF, title: "First Name")
        setupTF(tf: lastNameTF, title: "Last Name")
        setupTF(tf: emailTF, title: "Email")
        setupTF(tf: passwordTF, title: "Password")
        setupTF(tf: phoneNumberTf, title: "Phone Number")
        self.hideKeyboardWhenTappedAround()
        setupGradientView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupGradientView()
    }
    
    fileprivate func setupGradientView(){
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }
    
    override func viewDidLayoutSubviews() {
        setupGoButton()
    }
    
    ///Setup TextFields
    fileprivate func setupTF(tf: TextField, title: String){
        
        tf.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        tf.font = UIFont(name: "Century Gothic", size: 17)
        tf.textColor = UIColor.white
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholderAnimation = .hidden
        tf.placeholder = title
        tf.placeholderActiveColor = UIColor.white
        tf.placeholderNormalColor = UIColor.white
        tf.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    fileprivate func setupGoButton(){
        goButton.backgroundColor = UIColor.white
        goButton.setIcon(icon: .googleMaterialDesign(.arrowForward), iconSize: 25, color: #colorLiteral(red: 0.4, green: 0.6666666667, blue: 0.8823529412, alpha: 1), backgroundColor: UIColor.white, forState: .normal)
        
        //add functionality to the button
        goButton.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
    }

    @objc fileprivate func handleContinueButton(){
        let isTextfieldsEmpty = firstNameTF.isEmpty || lastNameTF.isEmpty || emailTF.isEmpty || passwordTF.isEmpty || phoneNumberTf.isEmpty
        
        if (isTextfieldsEmpty){
            self.present(popupForEmptyField(), animated: true, completion: nil)
            return
        }
            
        else if !validateEmail(enteredEmail: emailTF.text!){
            self.present(popupForInvalidEmail(), animated: true, completion: nil)
        }
            
        else if !validatePhoneNumber(number: phoneNumberTf.text!){
            self.present(popupForInvalidNumber(), animated: true, completion: nil)
        }
            
        else if !validatePassword(enteredPassword: passwordTF.text!){
            self.present(popupForInvalidPassword(), animated: true, completion: nil)
        }
            
        else {
            self.prepareAndAddBlurredLoader()
            if validateEmail(enteredEmail: emailTF.text!){
                MyAPIClient.sharedClient.createCourier(firstName: firstNameTF.text!, lastName: lastNameTF.text!, phoneNumber: phoneNumberTf.text!, email: emailTF.text!, password: passwordTF.text!) { (code) in
                    self.view.viewWithTag(101)?.removeFromSuperview()
                    self.view.viewWithTag(100)?.removeFromSuperview()
                    if code == "200"{
                        let finishedPopup = PopupDialog(title: "Success", message: "You have been successfully signed up, and will recieve an email soon on how to get your background check done. For now, you may log into the app using your credentials")
                        let continueButton = PopupDialogButton(title: "Continue", action: {
                            self.performSegue(withIdentifier: "toLoginPageFromSignUp", sender: self)
                        })
                        finishedPopup.addButton(continueButton)
                        self.present(finishedPopup, animated: true, completion: nil)
                    }
                    else{
                        let errorPopup = PopupDialog(title: "Error", message: "An error occurred. Please try again later")
                        self.present(errorPopup, animated: true, completion: nil)
                        return
                    }
                }
            }
            else{
                self.present(popupForInvalidEmail(), animated: true, completion: nil)
                return
            }
        }
    }
    
    fileprivate func validatePhoneNumber(number: String) -> Bool{
        
        let numberFormat = "[\\+][1][0-9]{10}"
        let numberPredicate = NSPredicate(format:"SELF MATCHES %@", numberFormat)
        return numberPredicate.evaluate(with: number)
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
        let popup = PopupDialog(title: title, message: message)
        return popup
    }
    
    fileprivate func popupForInvalidNumber() -> PopupDialog{
        let title = "Phone number"
        let message = "Please enter your phone number in the format: +1XXXXXXXXXX"
        let popup = PopupDialog(title: title, message: message)
        return popup
    }
    
    fileprivate func popupForInvalidEmail()-> PopupDialog {
        let title = "Invalid email"
        let message = "Please enter a valid email"
        let popup = PopupDialog(title: title, message: message)
        return popup
    }
    
    fileprivate func popupForInvalidPassword()-> PopupDialog {
        let title = "Invalid password"
        let message = "Your password must be at least six characters long and must contain at least one uppercase, at least one lowercase, one number, and one special charecter"
        let popup = PopupDialog(title: title, message: message)
        return popup
    }
    
}

extension UIColor{
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat){
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
