//
//  DisputeVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-02-20.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import Photos
import BSImagePicker
import Firebase
import FirebaseStorage
import PopupDialog

class DisputeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var selectedAssets:[PHAsset] = []
    var images: [UIImage] = []
    var job: Job!
    var disputeRef : DatabaseReference!
    @IBOutlet weak var pictureCollection: UICollectionView!
    
    @IBOutlet weak var disputeDescription: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        pictureCollection.delegate = self
        pictureCollection.dataSource = self
        let emailHash = HelperFunctions().MD5(string: (Auth.auth().currentUser?.email)!)
        disputeRef = Database.database().reference().child("Users").child(emailHash).child("dispute").child(job.jobID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CustomCollectionViewCell
        cell.cellImage.image = images[indexPath.row]
        cell.layer.cornerRadius = 25
        cell.layer.borderColor = UIColor.orange.cgColor
        cell.layer.borderWidth = 3
        return cell
    }
    
    
    
    @IBAction func addPhotoPressed(_ sender: UIButton) {
        self.images = []
        let picker = BSImagePickerViewController()
        picker.takePhotoIcon = #imageLiteral(resourceName: "emptyProfilePicture")
        picker.takePhotos = true
        self.bs_presentImagePickerController(picker, animated: true, select: { (asset) in
            
        }, deselect: { (asset) in
            
        }, cancel: { (assetsArray) in
            
        }, finish: { (assetsArray) in
            self.selectedAssets.append(contentsOf: assetsArray)
            self.convertAssetsAndAddToImages()
            self.selectedAssets = []
        }, completion: nil)
        
    }
    
    func convertAssetsAndAddToImages(){
        
        for i in (0 ..< self.selectedAssets.count){
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            var thumbnail = UIImage()
            option.isSynchronous = true
            
            manager.requestImage(for: self.selectedAssets[i], targetSize: CGSize(width: 50, height: 50), contentMode: .aspectFill, options: option, resultHandler: {(result, info)->Void in
                thumbnail = result!
                
            })
            let data = UIImageJPEGRepresentation(thumbnail, 0.7)
            let newImage = UIImage(data: data!)
            
            self.images.append(newImage!)
        }
        DispatchQueue.main.async {
            self.pictureCollection.reloadData()
        }
        
    }
    
    
    @IBAction func submitDisputePressed(_ sender: UIButton) {
        if self.images.isEmpty{
            self.present(self.popupForNoImages(), animated: true, completion: nil)
            return
        }
        
        let helper = HelperFunctions()
        let storageRef = Storage.storage().reference(forURL: "gs://blip-c1e83.appspot.com/").child(helper.MD5(string: (Auth.auth().currentUser?.email)!)).child("dispute")
        var counter = 0
        disputeRef.updateChildValues(["description": self.disputeDescription.text])
        for image in self.images{
            let data = UIImageJPEGRepresentation(image, 0.1)
            storageRef.putData(data!, metadata: nil, completion: { (metadata, error) in
                if error != nil{
                    print(error!.localizedDescription)
                    return
                }
                let pictureEvidence = metadata?.downloadURL()?.absoluteString
                let pictureEvidenceValues:[String:String] = ["image_\(counter)":pictureEvidence!]
                self.disputeRef.updateChildValues(pictureEvidenceValues)
//                self.dismiss(animated: true, completion: nil)
                counter = counter + 1
            })
        }
        let jobRef = Database.database().reference().child("AllJobs").child(self.job.jobID)
        jobRef.updateChildValues(["completed": true])
        self.performSegue(withIdentifier: "goToSellFromDispute", sender: nil)
        
    }
    
    @IBAction func closePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func popupForNoImages()-> PopupDialog {
        let title = "No Images Uploaded"
        let message = "Please upload some images as evidence"
        let okButton = CancelButton(title: "OK") {
            return
        }
        let popup = PopupDialog(title: title, message: message)
        popup.addButton(okButton)
        return popup
    }
    
}
