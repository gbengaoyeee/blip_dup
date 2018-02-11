//
//  ViewController.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2017-06-06.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import UIKit
import MessageUI
import Lottie
import Pastel
import Material

class AddNameVC: UIViewController {

    @IBOutlet weak var firstNameTF: TextField!
    @IBOutlet weak var lastNameTF: TextField!
    @IBOutlet weak var continueButtonName: UIButton!
    @IBOutlet weak var checkViewName: UIView!
    let errorName = LOTAnimationView(name: "error")
    let checkName = LOTAnimationView(name: "check")
    @IBOutlet weak var gradientView: PastelView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidAppear(true)
        self.prepareTitleTextField()
        self.navigationController?.navigationBar.isHidden = false
        self.gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.3476088047, green: 0.1101973727, blue: 0.08525472134, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
        self.hideKeyboardWhenTappedAround()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.continueButtonName.makeButtonAppear()
        self.gradientView.startAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.gradientView.startAnimation()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func continueButtonName(_ sender: Any) {
    
        self.dismissKeyboard()
        if (firstNameTF.text?.isEmpty != true && lastNameTF.text?.isEmpty != true){
            checkViewName.handledAnimation(Animation: checkName)
            self.continueButtonName.makeButtonDissapear()

            checkName.play()
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                self.checkName.stop()
                self.performSegue(withIdentifier: "ToEmailVerifyVC", sender: self)
            }
        }
            
        else{
            checkViewName.handledAnimation(Animation: errorName)
            self.continueButtonName.makeButtonDissapear()
            errorName.play()
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                self.errorName.stop()
                self.continueButtonName.makeButtonAppear()
            }
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ToEmailVerifyVC"){
            if let destination = segue.destination as? EmailVerifyVC{
                destination.firstName = firstNameTF.text
                destination.lastName = lastNameTF.text
            }
        }
    }
    
    func prepareTitleTextField(){
        self.firstNameTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        self.firstNameTF.font = UIFont(name: "Century Gothic", size: 17)
        self.firstNameTF.textColor = Color.white
        self.firstNameTF.placeholder = "First name"
        self.firstNameTF.placeholderActiveColor = Color.white
        self.firstNameTF.placeholderNormalColor = Color.white
        self.lastNameTF.placeholderLabel.font = UIFont(name: "Century Gothic", size: 17)
        self.lastNameTF.font = UIFont(name: "Century Gothic", size: 17)
        self.lastNameTF.textColor = Color.white
        self.lastNameTF.placeholder = "Last name"
        self.lastNameTF.placeholderActiveColor = Color.white
        self.lastNameTF.placeholderNormalColor = Color.white
    }
    
    func ERR_User_in_DataBase(){
        let alert = UIAlertController(title: "Email Already In Use", message: "Try using another email", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func ERR_Empty_Fields(){
        let alert = UIAlertController(title: "Empty Fields", message: "Fill In Required Fields", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action) in alert.dismiss(animated: true, completion: nil)}))
        self.present(alert, animated: true, completion: nil)
    }


}

