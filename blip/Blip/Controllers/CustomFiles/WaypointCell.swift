//
//  WaypointCell.swift
//  Blip
//
//  Created by Srikanth Srinivas on 6/4/18.
//  Copyright © 2018 Blip. All rights reserved.
//

import Foundation
import SwipeCellKit
import Material
import MapKit
import PopupDialog
import CoreLocation

class WaypointCell: SwipeTableViewCell{
    
    var type: String!
    var delivery: Delivery!
    var calls = 0
    let service = ServiceCalls.instance
    
    @IBOutlet weak var pullView: UIImageView!
    @IBOutlet weak var mainInstructionLabel: UILabel!
    @IBOutlet weak var subInstructionLabel: UILabel!
    @IBOutlet weak var callButton: RaisedButton!
    @IBOutlet weak var navigateButton: RaisedButton!
    
    var buttonAndTextColor: UIColor!
    var iconAndBackgroundColor: UIColor!
    
    override func awakeFromNib() {
        //
    }
    
    func prepareCell(){
        prepareCellColors()
        prepareInstructions(type: type, delivery: delivery)
        prepareButtons()
    }
    
    func prepareCellColors(){
        if type == "Pickup"{
            self.iconAndBackgroundColor = UIColor.white
            self.buttonAndTextColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
        }else{
            self.iconAndBackgroundColor = #colorLiteral(red: 0.3037296832, green: 0.6713039875, blue: 0.9027997255, alpha: 1)
            self.buttonAndTextColor = UIColor.white
        }
        self.mainInstructionLabel.textColor = buttonAndTextColor
        self.subInstructionLabel.textColor = buttonAndTextColor
        self.contentView.backgroundColor = iconAndBackgroundColor
        pullView.setIcon(icon: .googleMaterialDesign(.keyboardArrowLeft), textColor: buttonAndTextColor, backgroundColor: UIColor.clear, size: CGSize(size: 60))
    }
    
    func prepareButtons(){
        callButton.setIcon(icon: .googleMaterialDesign(.call), iconSize: 30, color: self.iconAndBackgroundColor, backgroundColor: self.buttonAndTextColor, forState: .normal)
        navigateButton.setIcon(icon: .googleMaterialDesign(.navigation), iconSize: 30, color: self.iconAndBackgroundColor, backgroundColor: self.buttonAndTextColor, forState: .normal)
        callButton.makeCircular()
        navigateButton.makeCircular()
    }
    
    func prepareInstructions(type: String, delivery: Delivery){
        if type == "Pickup"{
            self.mainInstructionLabel.text = delivery.pickupMainInstruction
            self.subInstructionLabel.text = delivery.pickupSubInstruction
        }
        else{
            self.mainInstructionLabel.text = delivery.deliveryMainInstruction
            self.subInstructionLabel.text = delivery.deliverySubInstruction
        }
    }
    
    @IBAction func navigateToPoint(_ sender: Any) {
        
        let location: CLLocationCoordinate2D!
        if self.type == "Pickup"{
            location = self.delivery.origin
        }
        else{
            location = self.delivery.deliveryLocation
        }
        let regionDistance:CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegionMakeWithDistance(location!, regionDistance, regionDistance)
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span) ]
        let placemark = MKPlacemark(coordinate: location!)
        let mapItem = MKMapItem(placemark: placemark)
        //Set mapItem name here which is also name of location
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude), completionHandler: { (placemarks, error) in
            if(error == nil){
                let clplaceMark = placemarks?[0]
                mapItem.name = self.parseAddress(placemark: clplaceMark!)
                mapItem.openInMaps(launchOptions: options)
            }
        })
        
        
    }
    
    @IBAction func callButton(_ sender: Any) {
        if type == "Pickup"{
            if let url:URL = URL(string: "tel://\(self.delivery.pickupNumber!)"), UIApplication.shared.canOpenURL(url){
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                calls += 1
            }
        }
        else{
            if let url:URL = URL(string: "tel://\(self.delivery.receiverPhoneNumber!)"), UIApplication.shared.canOpenURL(url){
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                calls += 1
            }
        }
    }
    
    ///Parses a CLPlacemark to a human readable address
    func parseAddress(placemark: CLPlacemark)->String{
        // put a space between "4" and "Melrose Place"
        let firstSpace = (placemark.subThoroughfare != nil && placemark.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (placemark.subThoroughfare != nil || placemark.thoroughfare != nil) && (placemark.subAdministrativeArea != nil || placemark.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (placemark.subAdministrativeArea != nil && placemark.administrativeArea != nil) ? " " : ""
        let thirdspace = (placemark.postalCode != nil) ? " " : ""
        
        let addressLine = String(
            format:"%@%@%@%@%@%@%@%@%@",
            // street number
            placemark.subThoroughfare ?? "",
            firstSpace,
            // street name
            placemark.thoroughfare ?? "",
            comma,
            // city
            placemark.locality ?? "",
            secondSpace,
            // state
            placemark.administrativeArea ?? "",
            thirdspace,
            //postalcode
            placemark.postalCode ?? ""
        )
        return addressLine
    }
}
