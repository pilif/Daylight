import CoreLocation
import Foundation

struct SharedLocationSnapshot: Codable, Equatable, Sendable {
  let latitude: Double
  let longitude: Double
  let timestamp: Date

  var location: CLLocation {
    CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
      altitude: 0,
      horizontalAccuracy: kCLLocationAccuracyThreeKilometers,
      verticalAccuracy: -1,
      timestamp: timestamp)
  }

  init(location: CLLocation) {
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude
    timestamp = location.timestamp
  }

  init(latitude: Double, longitude: Double, timestamp: Date) {
    self.latitude = latitude
    self.longitude = longitude
    self.timestamp = timestamp
  }
}

struct SharedLocationStore {
  static let suiteName = "group.me.pilif.Daylight"
  static let reloadDistance: CLLocationDistance = 3_000
  static let shared = SharedLocationStore()

  private static let snapshotKey = "last-location"
  private let defaults: UserDefaults

  init(defaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard) {
    self.defaults = defaults
  }

  func load() -> SharedLocationSnapshot? {
    guard let data = defaults.data(forKey: Self.snapshotKey) else {
      return nil
    }
    return try? JSONDecoder().decode(SharedLocationSnapshot.self, from: data)
  }

  func save(_ location: CLLocation) {
    guard CLLocationCoordinate2DIsValid(location.coordinate),
      let data = try? JSONEncoder().encode(SharedLocationSnapshot(location: location))
    else {
      return
    }
    defaults.set(data, forKey: Self.snapshotKey)
  }

  @discardableResult
  func migrateLegacyLocation(from legacyDefaults: UserDefaults = .standard) -> CLLocation? {
    if let location = load()?.location {
      return location
    }
    guard legacyDefaults.object(forKey: "lat") != nil,
      legacyDefaults.object(forKey: "long") != nil
    else {
      return nil
    }

    let location = CLLocation(
      latitude: legacyDefaults.double(forKey: "lat"),
      longitude: legacyDefaults.double(forKey: "long"))
    save(location)
    return location
  }

  static func requiresTimelineReload(
    from previous: CLLocation?, to current: CLLocation
  ) -> Bool {
    guard let previous else {
      return true
    }
    return current.distance(from: previous) >= reloadDistance
  }
}
