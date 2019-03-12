

import UIKit
import CoreLocation
import MapKit
import CoreMotion
import simd
import CoreData

class NewRunViewController: UIViewController {
  
  @IBOutlet weak var launchPromptStackView: UIStackView!
  @IBOutlet weak var dataStackView: UIStackView!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapContainerView: UIView!
  @IBOutlet weak var vAccLabel: UILabel!
    
    
  @IBAction func startTapped() {
   startRun()
  myDeviceMotion()
  }
  
  @IBAction func stopTapped() {
    //Alert
    let alertController = UIAlertController(title: "End test?",
                                            message: "Do you wish to end your test?",
                                            preferredStyle: .actionSheet)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alertController.addAction(UIAlertAction(title: "Save", style: .default) { _ in
      self.stopRun()
      self.saveRun()
      self.performSegue(withIdentifier: .details, sender: nil)
    })
    alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
      self.stopRun()
      _ = self.navigationController?.popToRootViewController(animated: true)
    })
    
    present(alertController, animated: true)
    motionManager.stopDeviceMotionUpdates()
  }
    
  private var run: Run?
  //Variable for location manager
  private let locationManager = LocationManager.shared
  private var seconds = 0
  private var timer: Timer?
  private var distance = Measurement(value: 0, unit: UnitLength.meters)
  private var locationList: [CLLocation] = []
  private let motionManager = CMMotionManager()
  var motionList: [CMDeviceMotion] = []
  var vAcceleration : Double = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    dataStackView.isHidden = true
  }
  
  //Enable to stop location updates and timer
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    timer?.invalidate()
    locationManager.stopUpdatingLocation()
  }
  
  // Start a running
  private func startRun() {
    //Show a map while running
    mapContainerView.isHidden = false
    mapView.removeOverlays(mapView.overlays)
    
    launchPromptStackView.isHidden = true
    dataStackView.isHidden = false
    startButton.isHidden = true
    stopButton.isHidden = false
    
    //Reset all of the values
    seconds = 0
    distance = Measurement(value: 0, unit: UnitLength.meters)
    locationList.removeAll()
    motionList.removeAll()
    clearDataOfAcceleration()
    updateDisplay()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      self.eachSecond()
    }
    startLocationUpdates()
    
  }
  
  // Stop a running
  private func stopRun() {
    mapContainerView.isHidden = true
    launchPromptStackView.isHidden = false
    dataStackView.isHidden = true
    startButton.isHidden = false
    stopButton.isHidden = true
    
    //Stop tracking location
    locationManager.stopUpdatingLocation()
    motionManager.stopDeviceMotionUpdates()
  }
  
  //Function for location manager
  func eachSecond() {
    seconds += 1
    updateDisplay()
  }
  
  //Function for location manager
  private func updateDisplay() {
    let formattedDistance = FormatDisplay.distance(distance)
    let formattedTime = FormatDisplay.time(seconds)
    let formattedSpeed = FormatDisplay.pace(distance: distance,
                                           seconds: seconds,
                                           outputUnit: UnitSpeed.minutesPerMile)
    
    distanceLabel.text = "Distance:  \(formattedDistance)"
    timeLabel.text = "Time:  \(formattedTime)"
    paceLabel.text = "Speed:  \(formattedSpeed)"
  }
  
  
  //Make this class the delegate for Core Location
  private func startLocationUpdates() {
    locationManager.delegate = self
    locationManager.activityType = .fitness
    locationManager.distanceFilter = 5
    locationManager.startUpdatingLocation()
  }
  
  
  //Save the run's data
  private func saveRun() {
    //Initialize newRun's values
    let newRun = Run(context: CoreDataStack.context)
    newRun.distance = distance.value
    newRun.duration = Int16(seconds)
    newRun.timestamp = Date()
    
    
    //Recording and adding new values to the run
    for location in locationList {
      let locationObject = Location(context: CoreDataStack.context)
      locationObject.timestamp = location.timestamp
      locationObject.latitude = location.coordinate.latitude
      locationObject.longitude = location.coordinate.longitude
      newRun.addToLocations(locationObject)
    }
    
    for motion in motionList{
      let motionObject = Motion(context: CoreDataStack.context)
      motionObject.timestamp = motion.timestamp
      let xu = motion.userAcceleration.x
      let yu = motion.userAcceleration.y
      let zu = motion.userAcceleration.z
      let xg = motion.gravity.x
      let yg = motion.gravity.y
      let zg = motion.gravity.z
      let gravityVector = simd_double3(Double(xg),Double(yg),Double(zg))
      let userAccelerationVector = simd_double3(Double(xu),Double(yu),Double(zu))
      let zVector = gravityVector * userAccelerationVector
      self.vAcceleration = (simd_length(zVector)) * 9.8
      motionObject.verticalAcceleration = self.vAcceleration
      newRun.addToMotions(motionObject)
       print("Vertical Acceleration at this moment is \(self.vAcceleration)")
    }
    CoreDataStack.saveContext()
   
    run = newRun
  }
  
  private func myDeviceMotion(){
    motionManager.deviceMotionUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdates(to: OperationQueue.current!){
      (dataU, error) in
      print(dataU as Any)
      self.motionList.append(dataU!)
      if let trueDataU = dataU{
        self.view.reloadInputViews()
        let xu = trueDataU.userAcceleration.x
        let yu = trueDataU.userAcceleration.y
        let zu = trueDataU.userAcceleration.z
        let xg = trueDataU.gravity.x
        let yg = trueDataU.gravity.y
        let zg = trueDataU.gravity.z
        
        
        let gravityVector = simd_double3(Double(xg),Double(yg),Double(zg))
        let userAccelerationVector = simd_double3(Double(xu),Double(yu),Double(zu))
        
        let zVector = gravityVector * userAccelerationVector
        self.vAcceleration = (simd_length(zVector)) * 9.8
        
        self.vAccLabel.text = "Vertical Acceleration: \(Double(self.vAcceleration).rounded(toPlaces: 3)) m/s/s"
        
        //lxg's iphone has a system error of +0.009
        //          print(self.vAcceleration-0.009)
        //          print(Double(zVector.x * zVector.y * zVector.z).sign)
        
      }
    }
  }
  

  
  func clearDataOfAcceleration(){
    let managedObejectContext = CoreDataStack.context
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Motion")
    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    do{
      try managedObejectContext.execute(batchDeleteRequest)
      try managedObejectContext.save()
    }
   catch {
  print("Failed")
  }
  }
}


// Storyboard Segues
extension NewRunViewController: SegueHandlerType {
  enum SegueIdentifier: String {
    case details = "RunDetailsViewController"
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .details:
      let destination = segue.destination as! RunDetailsViewController
      destination.run = run
    }
  }
}

//Report location updates
extension NewRunViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for newLocation in locations {
      let howRecent = newLocation.timestamp.timeIntervalSinceNow
      guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
      
      if let lastLocation = locationList.last {
        let delta = newLocation.distance(from: lastLocation)
        distance = distance + Measurement(value: delta, unit: UnitLength.meters)
        //Focus on the area of the run
        let coordinates = [lastLocation.coordinate, newLocation.coordinate]
        mapView.add(MKPolyline(coordinates: coordinates, count: 2))
        let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 650, 650)
        mapView.setRegion(region, animated: true)

      }
      
      locationList.append(newLocation)
    }
  }
}


//Delegate for showing a map while running
extension NewRunViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let polyline = overlay as? MKPolyline else {
      return MKOverlayRenderer(overlay: overlay)
    }
    let renderer = MKPolylineRenderer(polyline: polyline)
    renderer.strokeColor = .blue
    renderer.lineWidth = 3
    return renderer
  }
}


extension Double{
  func rounded(toPlaces places: Int) -> Double{
    let divisor = pow (10.0, Double(places))
    return (self * divisor).rounded() / divisor
}
}
