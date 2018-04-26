//
//  File.swift
//  Blip
//
//  Created by Srikanth Srinivas on 8/6/17.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import Lottie
import Pastel
import CoreLocation

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
    
    func makeCircular(){

        self.layer.cornerRadius = self.frame.size.height/2
        self.clipsToBounds = true
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

    
    
    func handledAnimation(Animation: LOTAnimationView, width: CGFloat, height: CGFloat){
        
        self.addSubview(Animation)
        let yCenterConstraint = NSLayoutConstraint(item: Animation, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let xCenterConstraint = NSLayoutConstraint(item: Animation, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: Animation, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: width, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: Animation, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: height, constant: 0)
        self.addConstraints([xCenterConstraint,yCenterConstraint,widthConstraint,heightConstraint])
        Animation.translatesAutoresizingMaskIntoConstraints = false
        Animation.contentMode = .scaleAspectFill
        
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
    
    func ApplyOuterShadowToView(){
        self.layer.shadowOpacity = 0.5
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 4
    }
    
    func ApplyCornerRadiusToView(){
        self.layer.cornerRadius = 7
        self.clipsToBounds = true
    }
    
}

extension UIViewController{
    
    func removedBlurredLoader(animation: LOTAnimationView){
        
        animation.stop()
        if let loadingViewAfterStripe = self.view.viewWithTag(100){
            loadingViewAfterStripe.removeFromSuperview()
        }
        if let blurredViewAfterStripe = self.view.viewWithTag(101){
            blurredViewAfterStripe.removeFromSuperview()
        }
    }
    
    func prepareAndAddBlurredLoader(){
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.tag = 101
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(blurEffectView)
        let loadingView = UIView()
        loadingView.tag = 100
        loadingView.frame.size = CGSize(width: 200, height: 200)
        loadingView.frame.origin = self.view.bounds.origin
        loadingView.center = self.view.convert(self.view.center, from: loadingView)
        let loadingAnimation = LOTAnimationView(name: "loading")
        loadingView.handledAnimation(Animation: loadingAnimation, width: 1, height: 1)
        self.view.addSubview(loadingView)
        loadingAnimation.play()
        loadingAnimation.loopAnimation = true
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIButton{
    
    func ApplyOuterShadowToButton(){
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.5)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 3
    }
    
    func ApplyCornerRadius(){
        self.layer.cornerRadius = 7
        self.clipsToBounds = true
    }
    
    func makeButtonDissapear(){
        self.alpha = 0
    }
    
    func makeButtonAppear(){
        self.alpha = 1
    }
    
}

public extension UIWindow {
    
    /// Transition Options
    public struct TransitionOptions {
        
        /// Curve of animation
        ///
        /// - linear: linear
        /// - easeIn: ease in
        /// - easeOut: ease out
        /// - easeInOut: ease in - ease out
        public enum Curve {
            case linear
            case easeIn
            case easeOut
            case easeInOut
            
            /// Return the media timing function associated with curve
            internal var function: CAMediaTimingFunction {
                let key: String!
                switch self {
                case .linear:        key = kCAMediaTimingFunctionLinear
                case .easeIn:        key = kCAMediaTimingFunctionEaseIn
                case .easeOut:        key = kCAMediaTimingFunctionEaseOut
                case .easeInOut:    key = kCAMediaTimingFunctionEaseInEaseOut
                }
                return CAMediaTimingFunction(name: key)
            }
        }
        
        /// Direction of the animation
        ///
        /// - fade: fade to new controller
        /// - toTop: slide from bottom to top
        /// - toBottom: slide from top to bottom
        /// - toLeft: pop to left
        /// - toRight: push to right
        public enum Direction {
            case fade
            case toTop
            case toBottom
            case toLeft
            case toRight
            
            /// Return the associated transition
            ///
            /// - Returns: transition
            internal func transition() -> CATransition {
                let transition = CATransition()
                transition.type = kCATransitionPush
                switch self {
                case .fade:
                    transition.type = kCATransitionFade
                    transition.subtype = nil
                case .toLeft:
                    transition.subtype = kCATransitionFromLeft
                case .toRight:
                    transition.subtype = kCATransitionFromRight
                case .toTop:
                    transition.subtype = kCATransitionFromTop
                case .toBottom:
                    transition.subtype = kCATransitionFromBottom
                }
                return transition
            }
        }
        
        /// Background of the transition
        ///
        /// - solidColor: solid color
        /// - customView: custom view
        public enum Background {
            case solidColor(_: UIColor)
            case customView(_: UIView)
        }
        
        /// Duration of the animation (default is 0.20s)
        public var duration: TimeInterval = 0.20
        
        /// Direction of the transition (default is `toRight`)
        public var direction: TransitionOptions.Direction = .toRight
        
        /// Style of the transition (default is `linear`)
        public var style: TransitionOptions.Curve = .linear
        
        /// Background of the transition (default is `nil`)
        public var background: TransitionOptions.Background? = nil
        
        /// Initialize a new options object with given direction and curve
        ///
        /// - Parameters:
        ///   - direction: direction
        ///   - style: style
        public init(direction: TransitionOptions.Direction = .toRight, style: TransitionOptions.Curve = .linear) {
            self.direction = direction
            self.style = style
        }
        
        public init() { }
        
        /// Return the animation to perform for given options object
        internal var animation: CATransition {
            let transition = self.direction.transition()
            transition.duration = self.duration
            transition.timingFunction = self.style.function
            return transition
        }
    }
    
    
    /// Change the root view controller of the window
    ///
    /// - Parameters:
    ///   - controller: controller to set
    ///   - options: options of the transition
    public func setRootViewController(_ controller: UIViewController, options: TransitionOptions = TransitionOptions()) {
        
        var transitionWnd: UIWindow? = nil
        if let background = options.background {
            transitionWnd = UIWindow(frame: UIScreen.main.bounds)
            switch background {
            case .customView(let view):
                transitionWnd?.rootViewController = UIViewController.newController(withView: view, frame: transitionWnd!.bounds)
            case .solidColor(let color):
                transitionWnd?.backgroundColor = color
            }
            transitionWnd?.makeKeyAndVisible()
        }
        
        // Make animation
        self.layer.add(options.animation, forKey: kCATransition)
        self.rootViewController = controller
        self.makeKeyAndVisible()
        
        if let wnd = transitionWnd {
            DispatchQueue.main.asyncAfter(deadline: (.now() + 1 + options.duration), execute: {
                wnd.removeFromSuperview()
            })
        }
    }
}

internal extension UIViewController {
    
    /// Create a new empty controller instance with given view
    ///
    /// - Parameters:
    ///   - view: view
    ///   - frame: frame
    /// - Returns: instance
    static func newController(withView view: UIView, frame: CGRect) -> UIViewController {
        view.frame = frame
        let controller = UIViewController()
        controller.view = view
        return controller
    }
    
    func generateRandomCoordinates(currentLoc: CLLocationCoordinate2D, min: UInt32, max: UInt32)-> CLLocationCoordinate2D {
        //Get the Current Location's longitude and latitude
        let currentLong = currentLoc.longitude
        let currentLat = currentLoc.latitude
        
        //1 KiloMeter = 0.00900900900901° So, 1 Meter = 0.00900900900901 / 1000
        let meterCord = 0.00900900900901 / 1000
        
        //Generate random Meters between the maximum and minimum Meters
        let randomMeters = UInt(arc4random_uniform(max) + min)
        
        //then Generating Random numbers for different Methods
        let randomPM = arc4random_uniform(6)
        
        //Then we convert the distance in meters to coordinates by Multiplying number of meters with 1 Meter Coordinate
        let metersCordN = meterCord * Double(randomMeters)
        
        //here we generate the last Coordinates
        if randomPM == 0 {
            return CLLocationCoordinate2D(latitude: currentLat + metersCordN, longitude: currentLong + metersCordN)
        }else if randomPM == 1 {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong - metersCordN)
        }else if randomPM == 2 {
            return CLLocationCoordinate2D(latitude: currentLat + metersCordN, longitude: currentLong - metersCordN)
        }else if randomPM == 3 {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong + metersCordN)
        }else if randomPM == 4 {
            return CLLocationCoordinate2D(latitude: currentLat, longitude: currentLong - metersCordN)
        }else {
            return CLLocationCoordinate2D(latitude: currentLat - metersCordN, longitude: currentLong)
        }
        
    }
    
}

extension PastelView{
    
    func prepareDefaultPastelView(){
        
        let colors = [#colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1), #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), #colorLiteral(red: 0.2796384096, green: 0.4718205929, blue: 1, alpha: 1)]
        self.setColors(colors)
        self.animationDuration = 2
    }
    
    func prepareCustomPastelViewWithColors(colors: [UIColor]){
        
        self.setColors(colors)
        self.animationDuration = 3
    }
    
}
