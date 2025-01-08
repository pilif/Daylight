import CoreLocation
import Foundation

class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var authorizationStatus: CLAuthorizationStatus
  @Published var lastSeenLocation: CLLocation?

  private let locationManager: CLLocationManager

  override init() {
    locationManager = CLLocationManager()
    authorizationStatus = locationManager.authorizationStatus

    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    if let prev = UserDefaults.standard.object(forKey: "lat") as? NSObject {
      let lat = UserDefaults.standard.double(forKey: "lat")
      let long = UserDefaults.standard.double(forKey: "long")
      lastSeenLocation = CLLocation(latitude: lat, longitude: long)
    }
  }

  func requestPermission() {
    locationManager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
    if locationManager.authorizationStatus == .authorizedAlways
      || locationManager.authorizationStatus == .authorizedWhenInUse
    {
      startMonitoring()
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    lastSeenLocation = locations.first
    if let lastSeenLocation {
      UserDefaults.standard.set(lastSeenLocation.coordinate.latitude, forKey: "lat")
      UserDefaults.standard.set(lastSeenLocation.coordinate.longitude, forKey: "long")
    }
  }

  private func startMonitoring() {
    locationManager.startUpdatingLocation()
  }
}
