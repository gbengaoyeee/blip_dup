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

/// I did this to leverage Srikanth's selfishness so he SHARES the work and DOESNT do the whole thing HIMSELF AND I HOPE HE SEES THIS ;(
class NewSignUpVC: UIViewController {

    @IBOutlet var gradientView: PastelView!
    
    let headerLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 46.5, y: 45, width: 282, height: 37))
        label.text = "Lets get you started"
        label.font = UIFont(name: "CenturyGothic-Bold", size: 30)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let firstNameTF: TextField = {
        let tf = TextField()
        tf.placeholderLabel.font = UIFont(name: "CenturyGothic", size: 17)
        tf.font = UIFont(name: "CenturyGothic", size: 17)
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholder = "First Name"
        tf.placeholderLabel.alpha = 0.6
        tf.placeholderActiveColor = UIColor(r: 236, g: 236, b: 236)
        tf.placeholderNormalColor = UIColor(r: 236, g: 236, b: 236)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let lastNameTF: TextField = {
        let tf = TextField()
        tf.placeholderLabel.font = UIFont(name: "CenturyGothic", size: 17)
        tf.font = UIFont(name: "CenturyGothic", size: 17)
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholder = "Last Name"
        tf.placeholderLabel.alpha = 0.6
        tf.placeholderActiveColor = UIColor(r: 236, g: 236, b: 236)
        tf.placeholderNormalColor = UIColor(r: 236, g: 236, b: 236)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let emailTF: TextField = {
        let tf = TextField()
        tf.placeholderLabel.font = UIFont(name: "CenturyGothic", size: 17)
        tf.font = UIFont(name: "CenturyGothic", size: 17)
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholder = "Email"
        tf.placeholderLabel.alpha = 0.6
        tf.placeholderActiveColor = UIColor(r: 236, g: 236, b: 236)
        tf.placeholderNormalColor = UIColor(r: 236, g: 236, b: 236)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let passwordTF: TextField = {
        let tf = TextField()
        tf.isSecureTextEntry = true
        tf.placeholderLabel.font = UIFont(name: "CenturyGothic", size: 17)
        tf.font = UIFont(name: "CenturyGothic", size: 17)
        tf.autocorrectionType = .no
        tf.textColor = Color.white
        tf.placeholder = "Password"
        tf.placeholderLabel.alpha = 0.6
        tf.placeholderActiveColor = UIColor(r: 236, g: 236, b: 236)
        tf.placeholderNormalColor = UIColor(r: 236, g: 236, b: 236)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let continueButton: RaisedButton = {
        let button = RaisedButton(title: "Continue")
        button.titleLabel?.font = UIFont(name: "CenturyGothic", size: 17)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.titleColor = UIColor(r: 103, g: 169, b: 225)
        button.pulseColor = UIColor(r: 103, g: 169, b: 225)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        view.backgroundColor = UIColor.blue
        addViews()
        setupHeaderLabel()
        setupFirstNameTF()
        setupLastNameTF()
        setupEmailTF()
        setupPasswordTF()
        setupContinueButton()
//        setupGradientView()
    }
    
    fileprivate func setupGradientView(){
        gradientView.prepareDefaultPastelView()
        gradientView.startAnimation()
    }
    
    ///Add subviews to the view
    fileprivate func addViews(){
        view.addSubview(headerLabel)
        view.addSubview(firstNameTF)
        view.addSubview(lastNameTF)
        view.addSubview(emailTF)
        view.addSubview(passwordTF)
        view.addSubview(continueButton)
    }

    ///Header label constraints
    fileprivate func setupHeaderLabel(){
        //need x, y, width, height, constraints
        guard let topConstraint = self.navigationController?.navigationBar.frame.height else{return}
        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstraint + 10).isActive = true
        headerLabel.widthAnchor.constraint(equalToConstant: 282).isActive = true
        headerLabel.heightAnchor.constraint(equalToConstant: 37).isActive = true
    }
    
    ///First name textfield constraints
    fileprivate func setupFirstNameTF(){
        //need x, y, width, height, constraints
        firstNameTF.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        firstNameTF.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        firstNameTF.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 50).isActive = true
        firstNameTF.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    ///Last name textfield constraints
    fileprivate func setupLastNameTF(){
        //need x, y, width, height, constraints
        lastNameTF.topAnchor.constraint(equalTo: firstNameTF.bottomAnchor, constant: 30).isActive = true
        
        lastNameTF.leftAnchor.constraint(equalTo: firstNameTF.leftAnchor).isActive = true
        lastNameTF.rightAnchor.constraint(equalTo: firstNameTF.rightAnchor).isActive = true
        lastNameTF.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    ///Email textfield constraints
    fileprivate func setupEmailTF(){
        //need x, y, width, height, constraints
        emailTF.topAnchor.constraint(equalTo: firstNameTF.topAnchor).isActive = true
//
        emailTF.leftAnchor.constraint(equalTo: firstNameTF.rightAnchor, constant: 30).isActive = true
        emailTF.widthAnchor.constraint(equalTo: firstNameTF.widthAnchor).isActive = true
//        emailTF.rightAnchor.constraint(equalTo: lastNameTF.rightAnchor).isActive = true
        emailTF.heightAnchor.constraint(equalTo: firstNameTF.heightAnchor).isActive = true
    }
    ///Password textfield constraints
    fileprivate func setupPasswordTF(){
        //need x, y, width, height, constraints
        passwordTF.topAnchor.constraint(equalTo: lastNameTF.topAnchor).isActive = true

        passwordTF.leftAnchor.constraint(equalTo: lastNameTF.rightAnchor, constant: 30).isActive = true
        passwordTF.widthAnchor.constraint(equalTo: lastNameTF.widthAnchor).isActive = true
//        passwordTF.rightAnchor.constraint(equalTo: emailTF.rightAnchor).isActive = true
        passwordTF.heightAnchor.constraint(equalTo: lastNameTF.heightAnchor).isActive = true
    }
    
    fileprivate func setupContinueButton(){
        //need x, y, width, height, constraints
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        continueButton.topAnchor.constraint(equalTo: lastNameTF.bottomAnchor, constant: 30).isActive = true
        continueButton.widthAnchor.constraint(equalTo: passwordTF.widthAnchor).isActive = true
        continueButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //add functionality to the button
        continueButton.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
    }

    @objc fileprivate func handleContinueButton(){
        let isTextfieldsEmpty = firstNameTF.isEmpty || lastNameTF.isEmpty || emailTF.isEmpty || passwordTF.isEmpty
        
        
        if (isTextfieldsEmpty){// there is empty field(s)
            self.present(popupForEmptyField(), animated: true, completion: nil)
        }
        //REMEMBER TO UNCOMMENT AFTER DONE SIGN UP
        else if !(validateEmail(enteredEmail: (emailTF.text)!)){
            self.present(popupForInvalidEmail(), animated: true, completion: nil)
        }
//        else if !(validatePassword(enteredPassword: (passwordTF.text)!)){
//            self.present(popupForInvalidPassword(), animated: true, completion: nil)
//        }
            
        //if all fields have been filled up and email is valid
        else{
            self.performSegue(withIdentifier: "choosePicture", sender: nil)
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
        let title = "Empty fields!!!"
        let message = "Please enter required information inside all fields"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
    fileprivate func popupForInvalidEmail()-> PopupDialog {
        let title = "Invalid email!!!"
        let message = "Please enter a valid email"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
    fileprivate func popupForInvalidPassword()-> PopupDialog {
        let title = "Invalid password!!!"
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
