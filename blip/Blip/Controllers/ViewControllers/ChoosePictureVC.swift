//
//  ChoosePictureVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-04-03.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Material
import Pastel

class ChoosePictureVC: UIViewController {

    let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose a profile picture"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "CenturyGothic-Bold", size: 30)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let bodyLabel: UILabel = {
        let label = UILabel()
        label.text = "We require our users to verify their identity for safety reasons. Please upload a photo of yourself"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont(name: "CenturyGothic", size: 22)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let profileImageView: UIImageView = {
        let imageview = UIImageView()
        imageview.isUserInteractionEnabled = true
        imageview.contentMode = .scaleAspectFill
        imageview.backgroundColor = .red
        imageview.layer.cornerRadius = 10
        imageview.layer.masksToBounds = true
        imageview.translatesAutoresizingMaskIntoConstraints = false
        return imageview
    }()
    
    let addPhotoView: UIView = {
        let view = UIView(frame: CGRect(x: 20, y: 30, width: 30, height: 30))
        view.isUserInteractionEnabled = true
        view.backgroundColor = .green
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        view.backgroundColor = UIColor(r: 121, g: 214, b: 249)
        addViews()
        setupHeaderLabel()
        setupBodyLabel()
        setupProfileImageView()
        setupContinueButton()
    }
    
    fileprivate func addViews(){
        view.addSubview(headerLabel)
        view.addSubview(bodyLabel)
        view.addSubview(profileImageView)
        profileImageView.addSubview(addPhotoView)
        view.addSubview(continueButton)
    }
    
    ///Header label constraints
    fileprivate func setupHeaderLabel(){
        //need x, y, width, height, constraints
        guard let topConstraint = self.navigationController?.navigationBar.frame.height else{return}
        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstraint + 10).isActive = true
        headerLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20).isActive = true
//        headerLabel.heightAnchor.constraint(equalToConstant: 37).isActive = true
    }
    
    fileprivate func setupBodyLabel(){
        //need x, y, width, height, constraints
        bodyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        bodyLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20).isActive = true
        bodyLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
    }
    
    fileprivate func setupProfileImageView(){
        //need x, y, width, height, constraints
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 20).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        setupAddPhotosView()
    }

    fileprivate func setupAddPhotosView(){
        //need x, y, width, height, constraints
        addPhotoView.leftAnchor.constraint(equalTo: profileImageView.leftAnchor, constant: 0).isActive = true
        addPhotoView.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 0).isActive = true
        addPhotoView.rightAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: -120).isActive = true
        addPhotoView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    fileprivate func setupContinueButton(){
        //need x, y, width, height, constraints
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        continueButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30).isActive = true
        continueButton.widthAnchor.constraint(equalToConstant: 244).isActive = true
        continueButton.heightAnchor.constraint(equalToConstant: 40)
    }
}
