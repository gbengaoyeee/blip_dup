//
//  File.swift
//  Blip
//
//  Created by Srikanth Srinivas on 8/6/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import Lottie

extension UIView{

    func leftToRightAnimation(duration: TimeInterval = 0.5, completionDelegate: AnyObject? = nil) {
        // Create a CATransition object
        let leftToRightTransition = CATransition()
            
        // Set its callback delegate to the completionDelegate that was provided
        if let delegate: AnyObject = completionDelegate {
            leftToRightTransition.delegate = (delegate as! CAAnimationDelegate)
        }
        
        
        leftToRightTransition.type = kCATransitionPush
        leftToRightTransition.subtype = kCATransitionFromRight
        leftToRightTransition.duration = duration
        leftToRightTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        leftToRightTransition.fillMode = kCAFillModeRemoved
            
        // Add the animation to the View's layer
        self.layer.add(leftToRightTransition, forKey: "leftToRightTransition")
    }
    
    func rightToLeftAnimation(duration: TimeInterval = 0.5, completionDelegate: AnyObject? = nil) {
        // Create a CATransition object
        let rightToLeftTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided
        if let delegate: AnyObject = completionDelegate {
            rightToLeftTransition.delegate = (delegate as! CAAnimationDelegate)
        }
        
        
        rightToLeftTransition.type = kCATransitionPush
        rightToLeftTransition.subtype = kCATransitionFromLeft
        rightToLeftTransition.duration = duration
        rightToLeftTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rightToLeftTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.add(rightToLeftTransition, forKey: "rightToLeftTransition")
    }

    
    
    func handledAnimation(Animation: LOTAnimationView){
        
        
        self.addSubview(Animation)
        let yCenterConstraint = NSLayoutConstraint(item: Animation, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let xCenterConstraint = NSLayoutConstraint(item: Animation, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: Animation, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: Animation, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        self.addConstraints([xCenterConstraint,yCenterConstraint,widthConstraint,heightConstraint])
        Animation.translatesAutoresizingMaskIntoConstraints = false
        Animation.contentMode = .scaleAspectFit
        
    }


    func returnHandledAnimation(filename: String, subView: UIView, tagNum: Int) -> LOTAnimationView{
    
        let animationView = LOTAnimationView(name: filename)
        subView.addSubview(animationView)
        let yCenterConstraint = NSLayoutConstraint(item: animationView, attribute: .centerY, relatedBy: .equal, toItem: subView, attribute: .centerY, multiplier: 1, constant: 0)
        let xCenterConstraint = NSLayoutConstraint(item: animationView, attribute: .centerX, relatedBy: .equal, toItem: subView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: animationView, attribute: .width, relatedBy: .equal, toItem: subView, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: animationView, attribute: .height, relatedBy: .equal, toItem: subView, attribute: .height, multiplier: 1, constant: 0)
        subView.addConstraints([xCenterConstraint,yCenterConstraint,widthConstraint,heightConstraint])
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.tag = tagNum
        return animationView
        
    }
    
    func returnHandledAnimationScaleToFill(filename: String, subView: UIView, tagNum: Int) -> LOTAnimationView{
        
        let animationView = LOTAnimationView(name: filename)
        subView.addSubview(animationView)
        let yCenterConstraint = NSLayoutConstraint(item: animationView, attribute: .centerY, relatedBy: .equal, toItem: subView, attribute: .centerY, multiplier: 1, constant: 0)
        let xCenterConstraint = NSLayoutConstraint(item: animationView, attribute: .centerX, relatedBy: .equal, toItem: subView, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: animationView, attribute: .width, relatedBy: .equal, toItem: subView, attribute: .width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: animationView, attribute: .height, relatedBy: .equal, toItem: subView, attribute: .height, multiplier: 1, constant: 0)
        subView.addConstraints([xCenterConstraint,yCenterConstraint,widthConstraint,heightConstraint])
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFill
        animationView.tag = tagNum
        return animationView
        
    }
    
    func makeAnimationDissapear(tag: Int){
        self.viewWithTag(tag)?.removeFromSuperview()
    }
    
}
