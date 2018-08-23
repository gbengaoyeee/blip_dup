
import UIKit
import Firebase
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import SRCountdownTimer
import Pulsator
import PopupDialog
import NotificationBannerSwift
import Material
import AVFoundation

class FoundJobVC: UIViewController, SRCountdownTimerDelegate {
    
    @IBOutlet weak var jobEarnings: UILabel!
    @IBOutlet weak var jobDistance: UILabel!
    @IBOutlet weak var pickupLabel: UILabel!
    @IBOutlet weak var pulseAnimationView: UIView!
    @IBOutlet weak var map: MGLMapView!
    @IBOutlet weak var countDownView: SRCountdownTimer!
    @IBOutlet weak var acceptJob: RaisedButton!
    
    var totalOptimizedTime: Int!
    var optimizationCode: Int!
    var player: AVAudioPlayer?
    var fromIndex = 0
    var toIndex = 1
    var job: Job!
    var service:ServiceCalls! = ServiceCalls.instance
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var waypoints: [BlipWaypoint]!
    var timer = Timer()
    var mglSource: MGLShapeSource! 
    var unfinishedJob: Bool!
    var currentType: String!
    var currentSubInstruction: String!
    var currentMainInstruction: String!
    var currentDelivery: Delivery!
    var isLastWaypoint: Bool!
    var handle:DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        parseRouteData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playNotificationSound()
        acceptJob.isUserInteractionEnabled = false
        observeForRemoved()
        prepareDataForNavigation { (bool) in
            if bool{
                self.acceptJob.isUserInteractionEnabled = true
            }else{
                self.preparePopupForErrors()
            }
        }
        if !unfinishedJob{
            setupTimer()
        }
        prepareMap()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        service.removeFirebaseObservers()
        //Remove the child removed observer handle
        Database.database().reference(withPath: "Couriers/\(self.service.emailHash!)/").removeAllObservers()
    }
    
    override func viewDidLayoutSubviews() {
        prepareCenterView()
        prepareMapViews()
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
            dest.job = self.job
        }
    }
    
    fileprivate func setupTimer(){
        countDownView.start(beginingValue: 28)
    }
    
    fileprivate func observeForRemoved(){
        let ref = Database.database().reference(withPath: "Couriers/\(self.service.emailHash!)/")
        self.handle = ref.observe(.childRemoved, with: { (snapshot) in
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func preparePopupForErrors(){
        let popup = PopupDialog(title: "Error", message: "An error occured when parsing job data", gestureDismissal: false)
        let okButton = PopupDialogButton(title: "Continue") {
            popup.dismiss()
            self.navigationController?.popToRootViewController(animated: true)
            self.service.putBackJobs()
            self.timer.invalidate()
        }
        popup.addButton(okButton)
        self.present(popup, animated: true, completion: nil)
    }
    
    func prepareDataForNavigation(completion: @escaping(Bool) -> ()){
        if let job = self.job{
            if self.optimizationCode == 3{
                // p1d1p2d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way4 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                way2.delivery = job.deliveries.first!!
                way3.delivery = job.deliveries.last!!
                way4.delivery = job.deliveries.last!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 1{
                // p1p2d1d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way3 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way4 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                way2.delivery = job.deliveries.last!!
                way3.delivery = job.deliveries.first!!
                way4.delivery = job.deliveries.last!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 2{
                // p1p2d2d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way3 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way4 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                way2.delivery = job.deliveries.last!!
                way3.delivery = job.deliveries.last!!
                way4.delivery = job.deliveries.first!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 6{
                // p2d2p1d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way4 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.last!!
                way2.delivery = job.deliveries.last!!
                way3.delivery = job.deliveries.first!!
                way4.delivery = job.deliveries.first!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 5{
                // p2p1d2d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way3 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way4 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.last!!
                way2.delivery = job.deliveries.first!!
                way3.delivery = job.deliveries.last!!
                way4.delivery = job.deliveries.first!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 4{
                // p2p1d1d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way3 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way4 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.last!!
                way2.delivery = job.deliveries.first!!
                way3.delivery = job.deliveries.first!!
                way4.delivery = job.deliveries.last!!
                self.waypoints = [way1, way2, way3, way4]
            }
            else if self.optimizationCode == 7{
                // One delivery
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = self.job.deliveries.first!!
                way2.delivery = self.job.deliveries.first!!
                self.waypoints = [way1, way2]
            }
            else if self.optimizationCode == 8{
                // d1d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = self.job.deliveries.first!!
                way2.delivery = self.job.deliveries.last!!
                self.waypoints = [way1, way2]
            }
            else if self.optimizationCode == 9{
                // d2d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = self.job.deliveries.last!!
                way2.delivery = self.job.deliveries.first!!
                self.waypoints = [way1, way2]
            }
            else if self.optimizationCode == 10{
                // p2d1d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.last!!
                way2.delivery = job.deliveries.first!!
                way3.delivery = job.deliveries.last!!
                self.waypoints = [way1, way2, way3]
            }
            else if self.optimizationCode == 11{
                // p2d2d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.last!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.last!!
                way2.delivery = job.deliveries.last!!
                way3.delivery = job.deliveries.first!!
                self.waypoints = [way1, way2, way3]
            }
            else if self.optimizationCode == 12{
                // p1d1d2
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                way2.delivery = job.deliveries.first!!
                way3.delivery = job.deliveries.last!!
                self.waypoints = [way1, way2, way3]
            }
            else if self.optimizationCode == 13{
                // p1d2d1
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.origin, coordinateAccuracy: -1, name: "Pickup")
                let way2 = BlipWaypoint(coordinate: job.deliveries.last!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                let way3 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                way2.delivery = job.deliveries.last!!
                way3.delivery = job.deliveries.first!!
                self.waypoints = [way1, way2, way3]
            }
            else if self.optimizationCode == 0{
                let way1 = BlipWaypoint(coordinate: job.deliveries.first!!.deliveryLocation, coordinateAccuracy: -1, name: "Delivery")
                way1.delivery = job.deliveries.first!!
                self.waypoints = [way1]
            }
            completion(true)
        }
        else{
            print("An error occured")
            completion(false)
        }
    }
    
    func prepareMap(){
        for delivery in job.deliveries{
            let annotation = MGLPointAnnotation()
            annotation.coordinate = delivery!.origin
            map.addAnnotation(annotation)
        }
        if let annotations = map.annotations{
            if annotations.count == 1{
                self.map.centerCoordinate = annotations.first!.coordinate
                let camera = MGLMapCamera(lookingAtCenter: map.centerCoordinate, fromDistance: 4500, pitch: 15, heading: 0)
                
                // Animate the camera movement over 5 seconds.
                map.setCamera(camera, withDuration: 3, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
            }
            else{
                map.showAnnotations(annotations, animated: true)
            }
        }
    }
    
    func prepareMapViews(){
        map.delegate = self
        map.makeCircular()
    }
    
    func prepareCenterView(){
        let pulsator = Pulsator()
        pulsator.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        pulsator.numPulse = 4
        pulsator.animationDuration = 4
        pulsator.radius = 400
        pulsator.repeatCount = .infinity
        pulsator.start()
        pulseAnimationView.layer.addSublayer(pulsator)
        countDownView.makeCircular()
        countDownView.clipsToBounds = true
    }
    
    @IBAction func acceptJobPressed(_ sender: Any) {
        timer.invalidate()
        service.checkGivenJobReference { (shouldSegue) in
            if shouldSegue{
                print(self.waypoints)
                self.service.setIsTakenOnGivenJobsAndStore(waypointList: self.waypoints!)
                self.player?.stop()
                self.performSegue(withIdentifier: "beginJob", sender: self)
            }
            else{
                self.preparePopupForErrors()
            }
        }
    }
}

extension FoundJobVC: MGLMapViewDelegate{
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let delivery = UIImage(named: "delivery")
        if let delivery = delivery{
            return MGLAnnotationImage(image: delivery.resizeImage(targetSize: CGSize(width: 40, height: 40)), reuseIdentifier: "delivery")
        }
        return nil
    }
}

extension FoundJobVC{
    
    func parseRouteData(){
        pickupLabel.text = "\(job.deliveries.count) Delivery(s)"
        jobDistance.text = "\(totalOptimizedTime/60) min(s)"
        let earningsText = String(format: "%.2f", arguments: [job.earnings])
        jobEarnings.text = "$ \(earningsText)"
    }
}

extension FoundJobVC{
    
    func playNotificationSound() {
        guard let url = Bundle.main.url(forResource: "notification", withExtension: "mp3") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            return
        }
    }
}

