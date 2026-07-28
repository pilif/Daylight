import CoreLocation
import Foundation
import WidgetKit

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
    lastSeenLocation = SharedLocationStore.shared.migrateLegacyLocation()
    if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
      startMonitoring()
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
    guard let newLocation = locations.last else {
      return
    }
    let previousLocation = SharedLocationStore.shared.load()?.location
    lastSeenLocation = newLocation
    SharedLocationStore.shared.save(newLocation)

    if SharedLocationStore.requiresTimelineReload(from: previousLocation, to: newLocation) {
      WidgetCenter.shared.reloadTimelines(ofKind: DaylightWidgetKind.nextSunTransition)
    }
  }

  private func startMonitoring() {
    locationManager.startUpdatingLocation()
  }
}
