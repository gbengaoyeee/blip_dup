
import UIKit
import Firebase
import Mapbox
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import SRCountdownTimer
import Pulsator
import PopupDialog
import NotificationBannerSwift
import Material

class FoundJobVC: UIViewController, SRCountdownTimerDelegate {
    
    @IBOutlet weak var jobEarnings: UILabel!
    @IBOutlet weak var jobDistance: UILabel!
    @IBOutlet weak var pickupLabel: UILabel!
    @IBOutlet weak var pulseAnimationView: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var countDownView: SRCountdownTimer!
    @IBOutlet weak var acceptJob: RaisedButton!
    
    var fromIndex = 0
    var toIndex = 1
    var job: Job!
    var service:ServiceCalls! = ServiceCalls.instance
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var waypoints: [BlipWaypoint]!
    var timer = Timer()
    var mglSource: MGLShapeSource!
    
    var currentType: String!
    var currentSubInstruction: String!
    var currentMainInstruction: String!
    var currentDelivery: Delivery!
    var isLastWaypoint: Bool!
    var navViewController: NavigationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        acceptJob.isUserInteractionEnabled = false
        prepareDataForNavigation { (bool) in
            if bool{
                self.acceptJob.isUserInteractionEnabled = true
            }else{
                self.preparePopupForErrors()
            }
        }
        setupTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        service.removeFirebaseObservers()
    }
    
    override func viewDidLayoutSubviews() {
        prepareCenterView()
        prepareMap()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "beginJob"{
            let dest = segue.destination as! OnJobVC
            dest.waypoints = self.waypoints
        }
    }
    
    fileprivate func setupTimer(){
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func handleTimer(){
        service.putBackJobs()
        timer.invalidate()
        self.navigationController?.popViewController(animated: true)
    }
    
    func preparePopupForErrors(){
        let popup = PopupDialog(title: "Error", message: "An error occured when parsing job data")
        let okButton = PopupDialogButton(title: "Continue") {
            popup.dismiss()
            self.navigationController?.popToRootViewController(animated: true)
        }
        popup.addButton(okButton)
    }
    
    func prepareDataForNavigation(completion: @escaping(Bool) -> ()){
        if let job = self.job{
            
            var distributions = ""
            for i in stride(from: 0, to: 2*(job.deliveries.count - job.getUnfinishedDeliveries().count), by: 1) {
                
                if i%2 != 0{
                    distributions = distributions + "\(i+1);"
                }
                else{
                    distributions = distributions + "\(i+1),"
                }
            }
            distributions = String(distributions.dropLast())
            MyAPIClient.sharedClient.optimizeRoute(locations: job.locList, distributions: distributions) { (waypointData, routeData, error) in
                if error == nil{
                    if let waypointData = waypointData{
                        self.waypoints = self.parseDataFromOptimization(waypointData: waypointData)
                    }
                    if let routeData = routeData{
                        self.parseRouteData(routeData: routeData)
                    }
                    completion(true)
                }
                else{
                    completion(false)
                    print(error!)
                    self.service.putBackJobs()
                }
            }
        }
        else{
            completion(false)
            print("An Error occured. No Job was passed")
        }
    }
    
    func prepareMap(){
        map.delegate = self
        map.makeCircular()
        for delivery in job.deliveries{
            let annotation = MGLPointAnnotation()
            annotation.coordinate = delivery.origin
            map.addAnnotation(annotation)
        }
        if let annotations = map.annotations{
            if annotations.count == 1{
                self.map.centerCoordinate = annotations.first!.coordinate
                self.map.setZoomLevel(10, animated: true)
            }
            else{
                map.showAnnotations(annotations, animated: true)
            }
        }
    }
    
    func prepareCenterView(){
        let pulsator = Pulsator()
        pulsator.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        pulsator.numPulse = 4
        pulsator.animationDuration = 4
        pulsator.radius = 400
        pulsator.repeatCount = .infinity
        pulsator.start()
        pulseAnimationView.layer.addSublayer(pulsator)
        countDownView.makeCircular()
        countDownView.clipsToBounds = true
        countDownView.start(beginingValue: 30)
    }
    
    @IBAction func acceptJobPressed(_ sender: Any) {
        timer.invalidate()
        self.service.setIsTakenOnGivenJobsAndStore(waypointList: self.waypoints)
        self.performSegue(withIdentifier: "beginJob", sender: self)
    }
}

extension FoundJobVC: MGLMapViewDelegate{
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let delivery = UIImage(named: "delivery")
        if let delivery = delivery{
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(size: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
}

extension FoundJobVC{
    
    func parseDataFromOptimization(waypointData: [[String: AnyObject]]) -> [BlipWaypoint]{
        var waypointList = [BlipWaypoint]()
        var i = 0
        while waypointList.count < (waypointData.count){
            for element in waypointData{
                
                let loc = CLLocation(latitude: (element["location"]! as! [Double])[1], longitude: (element["location"]! as! [Double])[0])
                let way = BlipWaypoint(location: loc, heading: nil, name: nil)
                if element["waypoint_index"] as? Int == i{
                    waypointList.append(way)
                    i += 1
                }
            }
        }
        for way in waypointList{
            
            var dist: Double! = 20000
            var index: Int!
            for loc in job.locList{
                
                if dist > loc.distance(to: way.coordinate){
                    dist = loc.distance(to: way.coordinate)
                    index = job.locList.index(of: loc)
                }
            }
            way.delivery = getDeliveryFor(waypoint: way)
            if way.delivery.state != nil{
                way.name = "Delivery"
            }
            else{
                if index == 0{
                    way.name = "Origin"
                }
                else if index%2 == 0{
                    way.name = "Delivery"
                }
                else{
                    way.name = "Pickup"
                }
            }
        }
        return waypointList
    }
    
    
    func getWaypointFor(coordinate: CLLocationCoordinate2D) -> BlipWaypoint{
        
        var dist: Double! = 20000
        var index: Int!
        var i = 0
        for waypoint in self.waypoints{
            if dist > waypoint.coordinate.distance(to: coordinate){
                dist = waypoint.coordinate.distance(to: coordinate)
                index = i
            }
            i += 1
        }
        return self.waypoints[index]
    }
    
    
    func getDeliveryFor(waypoint: Waypoint) -> Delivery?{
        var dist: Double! = 20000
        var index: Int!
        var i = 0
        for delivery in job.deliveries{
            
            if dist > min(delivery.origin.distance(to: waypoint.coordinate), (delivery.origin.distance(to: waypoint.coordinate))){
                dist = min(delivery.origin.distance(to: waypoint.coordinate), (delivery.origin.distance(to: waypoint.coordinate)))
                index = i
            }
            i += 1
        }
        if let index = index{
            return job.deliveries[index]
        }
        return nil
    }
    
    func instructionsUponArrivalAt(waypoint: Waypoint) -> [String]?{
        if let delivery = getDeliveryFor(waypoint: waypoint){
            if let name = waypoint.name{
                if name == "Pickup"{
                    return [delivery.pickupMainInstruction, delivery.pickupSubInstruction]
                }
                else if name == "Delivery"{
                    return [delivery.deliveryMainInstruction, delivery.deliverySubInstruction]
                }
            }
        }
        return nil
    }
    
    func parseRouteData(routeData: [String: AnyObject]){
        
        let estimatedDistance = routeData["distance"] as! NSNumber
        let distanceInKm = (estimatedDistance.intValue/1000)
        pickupLabel.text = "\(job.deliveries.count) Delivery(s)"
        jobDistance.text = "\(distanceInKm) km"
        let earningsText = String(format: "%.2f", arguments: [job.earnings])
        jobEarnings.text = "$ \(earningsText)"
    }
}

