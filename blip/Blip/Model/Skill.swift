//
//  Skill.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2017-06-16.
//  Copyright © 2017 Gbenga Ayobami. All rights reserved.
//

import Foundation
import UIKit

class Skill: Equatable{
    
    private var skillName: String
    private var experienceLevel: String
    private var overallSkillRating: Float
    private var skillRatingList: Array<Int>
    
    init(skillName: String, experienceLevel: String) {
        self.skillName = skillName
        self.experienceLevel = experienceLevel
        self.overallSkillRating = 0
        self.skillRatingList = Array()
    }
    
    
    func getSkillName()->String{
        return self.skillName
    }
    
    
    func getExperienceLevel()->String{
        return self.experienceLevel
    }
    
    /*
     return the average rating for this specific skill
     
     */
    func getOverallSkillRating()->Float{
        return self.overallSkillRating
    }
    
    func addSkillRating(ratings: Int){
        self.skillRatingList.append(ratings)
    }
    
    func setOverallSkillRating(){
        var ratingSum = 0
        let lst_length = self.skillRatingList.count
        for rating in skillRatingList{
            ratingSum = ratingSum + rating
        }
        self.overallSkillRating = Float(ratingSum/lst_length)
        
    }
    
}









func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.getSkillName() == rhs.getSkillName()
}
