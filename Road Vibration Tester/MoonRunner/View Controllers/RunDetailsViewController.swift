


import UIKit
import MapKit
import CoreMotion
import simd
import CoreData

class RunDetailsViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var vaccLabel: UILabel!
  @IBOutlet weak var maxVaaLabel: UILabel!
  @IBOutlet weak var minVaccLabel: UILabel!
  @IBOutlet weak var legendLabel: UILabel!
  
    
    
    
  var run: Run!
  var motionManager = CMMotionManager()
 
    
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
   
  }
  
  //Display the details of the running
  private func configureView() {
    let distance = Measurement(value: run.distance, unit: UnitLength.meters)
    let seconds = Int(run.duration)
    let formattedDistance = FormatDisplay.distance(distance)
    let formattedDate = FormatDisplay.date(run.timestamp)
    let formattedTime = FormatDisplay.time(seconds)
    let formattedSpeed = FormatDisplay.pace(distance: distance,
                                           seconds: seconds,
                                           outputUnit: UnitSpeed.minutesPerMile)
    
    distanceLabel.text = "Distance:  \(formattedDistance)"
    dateLabel.text = formattedDate
    timeLabel.text = "Time:  \(formattedTime)"
    paceLabel.text = "Speed:  \(formattedSpeed)"
    legendLabel.text = "Vertical Acceleration Magnitude"
    
    loadMap()
    
  }
  
  
  //Set the region for display
  private func mapRegion() -> MKCoordinateRegion? {
    guard
    let locations = self.run.locations,
      locations.count > 0
      else {
        return nil
    }
    
    let latitudes = locations.map { location -> Double in
      let location = location as! Location
      return location.latitude
    }
    
    let longitudes = locations.map { location -> Double in
      let location = location as! Location
      return location.longitude
    }
    
    let maxLat = latitudes.max()!
    let minLat = latitudes.min()!
    let maxLong = longitudes.max()!
    let minLong = longitudes.min()!
    
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                        longitude: (minLong + maxLong) / 2)
    let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5,
                                longitudeDelta: (maxLong - minLong) * 1.5)
    return MKCoordinateRegion(center: center, span: span)
  }
  
  
  //Creat a overlay line based on the magnitude of acceleration
  private func polyLineAcceleration() -> [MulticolorPolyline] {
    
    let locations = self.run.locations?.array as! [Location]
    var coordinates: [(CLLocation, CLLocation)] = []
    var verticalAccelerations: [Double] = []
    var minAcceleration = 0.0
    var maxAcceleration = 0.0
    var midAcceleration = 0.0
    // Record segment by using a startpoint and endpoints
    for (first, second) in zip(locations, locations.dropFirst()) {
      let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
      let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
      coordinates.append((start, end))
    }
    
    let fetchRequest : NSFetchRequest<Motion> = Motion.fetchRequest()
    do{
      let verticalAcceleration = try CoreDataStack.context.fetch(fetchRequest)
      for data in verticalAcceleration as [NSManagedObject]{
        verticalAccelerations.append(data.value(forKey: "verticalAcceleration") as! Double)
      }
    }
    catch{
      print("Failed")
    }
    
    minAcceleration = verticalAccelerations.min()!
    maxAcceleration = verticalAccelerations.max()!
    midAcceleration = verticalAccelerations.reduce(0,+) / Double(verticalAccelerations.count)
    print(minAcceleration)
    print(maxAcceleration)
    print(midAcceleration)
    vaccLabel.text = "Avg. Vertical Acceleration:  \(midAcceleration.rounded(toPlaces: 3)) m/s/s"
    maxVaaLabel.text = "Max Vertical Acceleration:  \(maxAcceleration.rounded(toPlaces: 3)) m/s/s"
    minVaccLabel.text = "Min Vertical Acceleration:  \(minAcceleration.rounded(toPlaces: 3)) m/s/s"
    
    //Creat a colorful line
    var segments: [MulticolorPolyline] = []
    for ((start, end),verticalAcceleration) in zip(coordinates, verticalAccelerations) {
      let coords = [start.coordinate, end.coordinate]
      let segment = MulticolorPolyline(coordinates: coords, count: 2)
      segment.color = segmentColor(verticalAcceleration: verticalAcceleration,
                                   midAcceleration: midAcceleration,
                                   slowestAcceleration: minAcceleration,
                                   fastestAcceleration: maxAcceleration)
      segments.append(segment)
    }
    return segments
  }
  
  
//Load a route in the map
 private func loadMap() {
    guard
        let locations = run.locations,
      locations.count > 0,
      let region = mapRegion()
      else {
        let alert = UIAlertController(title: "Error",
                                      message: "Sorry, this run has no locations saved",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
        return
    }
    mapView.setRegion(region, animated: true)
    mapView.addOverlays(polyLineAcceleration())
  }
  
  
  //Coloring
 private func segmentColor(verticalAcceleration: Double, midAcceleration: Double, slowestAcceleration: Double, fastestAcceleration: Double) -> UIColor {
    enum BaseColors {
      static let r_red: CGFloat = 1
      static let r_green: CGFloat = 20 / 255
      static let r_blue: CGFloat = 44 / 255
      
      static let y_red: CGFloat = 1
      static let y_green: CGFloat = 215 / 255
      static let y_blue: CGFloat = 0
      
      static let g_red: CGFloat = 0
      static let g_green: CGFloat = 146 / 255
      static let g_blue: CGFloat = 78 / 255
    }
    
    let red, green, blue: CGFloat
    
    if verticalAcceleration > midAcceleration {
      let ratio = CGFloat((verticalAcceleration - midAcceleration) / (fastestAcceleration - midAcceleration))
      red = BaseColors.y_red + ratio * (BaseColors.r_red - BaseColors.y_red)
      green = BaseColors.y_green + ratio * (BaseColors.r_green - BaseColors.y_green)
      blue = BaseColors.y_blue + ratio * (BaseColors.r_blue - BaseColors.y_blue)
     
    } else {
      let ratio = CGFloat((verticalAcceleration - slowestAcceleration) / (midAcceleration - slowestAcceleration))
      red = BaseColors.g_red + ratio * (BaseColors.y_red - BaseColors.g_red)
      green = BaseColors.g_green + ratio * (BaseColors.y_green - BaseColors.g_green)
      blue = BaseColors.g_blue + ratio * (BaseColors.y_blue - BaseColors.g_blue)
    }
    
    return UIColor(red: red, green: green, blue: blue, alpha: 1)
  }

}


//Draw a line in map
extension RunDetailsViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let polyline = overlay as? MulticolorPolyline else {
      return MKOverlayRenderer(overlay: overlay)
    }
    let renderer = MKPolylineRenderer(polyline: polyline)
    renderer.strokeColor = polyline.color
    renderer.lineWidth = 5
    return renderer
  }

}



