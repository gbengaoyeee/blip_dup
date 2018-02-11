//
//  OnboardingVCViewController.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-01-08.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import UIKit
import Lottie
import Pastel
import CHIPageControl

class OnboardingVCViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var gradientView: PastelView!
    @IBOutlet weak var pageControl: CHIPageControlFresno!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var serviceAnimationView: UIView!

    let serviceAnimation = LOTAnimationView(name: "onboarding")
    let serviceArray = ["Welcome to Blip, the worlds first marketplace for free time","Post jobs at custom locations that you need completed","Need a painter? Someone to move your boxes? Or just someone to pick up ice cream from the closest store for you? Hire other users to complete your tasks","Pay and get paid instantaneously, freelancing your free time to complete other users jobs","Hit get started to begin with a free account"]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        gradientView.animationDuration = 3.0
        gradientView.setColors([#colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1),#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)])
        self.navigationController?.navigationBar.isHidden = true
        prepareAnimation()
        setupScrollView()
        pageControl.numberOfPages = 5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        gradientView.startAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        gradientView.startAnimation()
    }
    
    func setupScrollView(){
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: self.view.frame.size.width * 5, height: scrollView.frame.size.height)
        scrollView.showsHorizontalScrollIndicator = false
        
        for stage in 0...4{
    
            let label = UILabel(frame: CGRect(x: scrollView.center.x + CGFloat(stage) * self.view.frame.size.width - 125 , y: 0, width: 250, height: self.scrollView.frame.size.height))
            label.font = UIFont(name: "CenturyGothic", size: 20)
            label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            label.textAlignment = .center
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.text = serviceArray[stage]
            scrollView.addSubview(label)
        }
        
    }
    
    @IBAction func GoToLGSU(_ sender: Any) {
        
        self.performSegue(withIdentifier: "goToLGSU", sender: self)
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        
        let progress = scrollView.contentOffset.x  / self.scrollView.contentSize.width * 1.08
        serviceAnimation.animationProgress = progress
        let pageProgress = scrollView.contentOffset.x / self.view.frame.size.width
        print(progress)

        pageControl.progress = Double(pageProgress)
    }
    

//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//
//        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
//        pageControl.currentPage = Int(pageNumber)
//    }
    
    func prepareAnimation(){
        
        serviceAnimationView.handledAnimation(Animation: serviceAnimation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
