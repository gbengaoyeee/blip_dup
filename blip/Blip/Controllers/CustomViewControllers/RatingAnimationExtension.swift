//
//  RatingAnimationExtension.swift
//  Blip
//
//  Created by Srikanth Srinivas on 2018-01-30.
//  Copyright © 2018 Gbenga Ayobami. All rights reserved.
//

import Foundation
import Lottie

extension LOTAnimationView{
    
    func playToRating(rating: CGFloat){
        
        let maxRating: CGFloat = 5.0
//        self.animationProgress = rating/maxRating
        self.play(toProgress: rating/maxRating, withCompletion: nil)
        print(self.animationProgress, "This is the animation progress")
    }
}
