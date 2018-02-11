////
////  AllJobs.swift
////  Blip
////
////  Created by Gbenga Ayobami on 2017-06-15.
////  Copyright © 2017 Gbenga Ayobami. All rights reserved.
////
//
//import Foundation
//import UIKit
//import CoreLocation
//
//// Singleton
//class AllJobs{
//    static let allPostedJobs: AllJobs = AllJobs()
//    private var globalList: [Job]
//    
//    private init() {
//        self.globalList = []
//    }
//    
//    func addJob_to_GlobalList(job: Job){
//        job.setJobID()
//        self.globalList.append(job)
//    }
//    
//    
//    func getAll_Available_Jobs()->[Job]{
//        return self.globalList
//    }
//    
//    func remove_Job_from_GlobalList(job: Job){
//        
//        if job.isOccupied(){
//            let ind = self.globalList.index(of: job)
//            self.globalList.remove(at: ind!)
//            
//        }
//    }
//    
//    
//    
//    func acceptJob(user: User, job: Job!){
//        let job_cpy = job
//        
//        if job_cpy != nil{
//            let jobIndex = self.globalList.index(of: job)
//            job.setJobTaker(jobTaker: user)
//            self.globalList.remove(at: jobIndex!)
//        }
//    }
//    
//    func declineJob(job: Job!){
//        let job_cpy = job
//        
//        if job_cpy != nil{
//            let jobIndex = self.globalList.index(of: job)
//            self.globalList.remove(at: jobIndex!)
//            self.globalList.append(job_cpy!)
//        }else{
//            return
//        }
//    }
//    
//    
//    
//    func putJobBack(job: Job){
//        self.globalList.append(job)
//    }
//    
//    
//    
//    func printAllJobs(){
//        for job in globalList{
//            print(job.getTitle())
//        }
//    }
//}
