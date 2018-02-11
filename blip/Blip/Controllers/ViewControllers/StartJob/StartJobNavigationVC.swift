import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox
import Material

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"
private typealias RouteRequestSuccess = (([Route]) -> Void)
private typealias RouteRequestFailure = ((NSError) -> Void)

enum ExampleMode {
    case `default`
    case custom
    case styled
    case multipleWaypoints
}

class StartJobNavigation: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, VoiceControllerDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var startButton: UIButton!

    //MARK: Properties
    let timer = Timer()
    let service = ServiceCalls()
    var waypoints: [Waypoint] = []
    var job: Job!
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    
    var routes: [Route]? {
        didSet {
            startButton.isEnabled = (routes?.count ?? 0 > 0)
            guard let routes = routes,
                let current = routes.first else { mapView?.removeRoutes(); return }
            
            mapView.showRoutes(routes)
            mapView.showWaypoints(current)
        }
    }
    
    // MARK: Directions Request Handlers
    
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.mapView.removeWaypoints()
        self?.routes = routes
        self?.waypoints = current.routeOptions.waypoints
    }
    
    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        self?.routes = nil //clear routes from the map
        print(error.localizedDescription)
    }
    
    
    var exampleMode: ExampleMode?
    
    var locationManager = CLLocationManager()
    
    var alertController: UIAlertController!
    
    lazy var multipleStopsAction: UIAlertAction = {
        return UIAlertAction(title: "Multiple Stops", style: .default, handler: { (action) in
            self.startMultipleWaypoints()
        })
    }()
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.navigationController?.navigationBar.isHidden = true
        self.navigationItem.hidesBackButton = true
        automaticallyAdjustsScrollViewInsets = false
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset the navigation styling to the defaults
        DayStyle().apply()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }
        
        if waypoints.count > 1 {
            waypoints = Array(waypoints.suffix(1))
            multipleStopsAction.isEnabled = true
        } else { //single waypoint
            multipleStopsAction.isEnabled = false
        }
        
        let coordinates = job.location.coordinate
        let waypoint = Waypoint(coordinate: coordinates)
        waypoint.coordinateAccuracy = -1
        waypoints.append(waypoint)
        
        if waypoints.count >= 2, !alertController.actions.contains(multipleStopsAction) {
            alertController.addAction(multipleStopsAction)
        }
        
        requestRoute()
    }

    
    @IBAction func startButtonPressed(_ sender: Any) {
        self.startBasicNavigation()
    }
    
    
    //MARK: - Public Methods
    //MARK: Route Requests
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        
        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "user")
        waypoints.insert(userWaypoint, at: 0)
        
        let options = NavigationRouteOptions(waypoints: waypoints)
        
        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
    }
    
    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        
        let handler: Directions.CompletionHandler = {(waypoints, potentialRoutes, potentialError) in
            if let error = potentialError, let fail = failure { return fail(error) }
            guard let routes = potentialRoutes else { return }
            return success(routes)
        }
        
        _ = Directions.shared.calculate(options, completionHandler: handler)
    }
    
    // MARK: Basic Navigation
    
    func startBasicNavigation() {
        guard let route = currentRoute else { return }
        
        exampleMode = .default
        
        let navVC = TBTNavigationVC(for: route)
        if let navjob = self.job{
            navVC.job = navjob
        }
        
        self.present(navVC, animated: true, completion: nil)
        
    }
    
    
    // MARK: Styling the default UI
    
    func startStyledNavigation() {
        guard let route = self.currentRoute else { return }
        
        exampleMode = .styled
        
        let styles = [CustomDayStyle(), CustomNightStyle()]
        
//        let navigationViewController = NavigationViewController(for: route, styles: styles, locationManager: navigationLocationManager())
        let navVc = TBTNavigationVC(for: route, styles: styles)
//        navigationViewController.delegate = self
        
        present(navVc, animated: true, completion: nil)
    }
    
    func navigationLocationManager() -> NavigationLocationManager {
        guard let route = currentRoute else { return NavigationLocationManager() }
        return NavigationLocationManager()
    }
    
    // MARK: Navigation with multiple waypoints
    
    func startMultipleWaypoints() {
        guard let route = self.currentRoute else { return }
        
        exampleMode = .multipleWaypoints
    }
}

//MARK: - NavigationMapViewDelegate
extension StartJobNavigation: NavigationMapViewDelegate {
    //NOT USEFUL HERE AT LEAST
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint) {
        guard let routeOptions = currentRoute?.routeOptions else { return }
        let modifiedOptions = routeOptions.without(waypoint: waypoint)
        
        let destroyWaypoint: (UIAlertAction) -> Void = {_ in self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure) }
        
        presentWaypointRemovalActionSheet(callback: destroyWaypoint)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        currentRoute = route
    }
    
    private func presentWaypointRemovalActionSheet(callback approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("Remove Waypoint?", comment: "Waypoint Removal Action Sheet Title")
        let message = NSLocalizedString("Would you like to remove this waypoint?", comment: "Waypoint Removal Action Sheet Message")
        let removeTitle = NSLocalizedString("Remove Waypoint", comment: "Waypoint Removal Action Item Title")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Waypoint Removal Action Sheet Cancel Item Title")
        
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: removeTitle, style: .destructive, handler: approve)
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        [remove, cancel].forEach(actionSheet.addAction(_:))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // To use these delegate methods, set the `VoiceControllerDelegate` on your `VoiceController`.
    //
    // Called when there is an error with speaking a voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: Error) {
        print(error.localizedDescription)
    }
    // Called when an instruction is interrupted by a new voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        print(interruptedInstruction.text, interruptingInstruction.text)
    }
    
    func voiceController(_ voiceController: RouteVoiceController, willSpeak instruction: SpokenInstruction, routeProgress: RouteProgress) -> SpokenInstruction? {
        return SpokenInstruction(distanceAlongStep: instruction.distanceAlongStep, text: "New Instruction!", ssmlText: "<speak>New Instruction!</speak>")
    }
}



/**
 To find more pieces of the UI to customize, checkout DayStyle.swift.
 */
//MARK: CustomDayStyle
class CustomDayStyle: DayStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .dayStyle
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}


//MARK: CustomNightStyle
class CustomNightStyle: NightStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .nightStyle
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .purple
    }
}

