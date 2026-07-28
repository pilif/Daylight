import CoreLocation
import Foundation
import Testing

@testable import Daylight_Watch_App

@Suite(.serialized)
struct SharedLocationStoreTests {
  @Test
  func savesAndLoadsLocation() {
    withStores { store, _ in
      let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 47.37, longitude: 8.54),
        altitude: 0,
        horizontalAccuracy: 250,
        verticalAccuracy: -1,
        timestamp: Date(timeIntervalSince1970: 1234))

      store.save(location)

      #expect(store.load()?.latitude == location.coordinate.latitude)
      #expect(store.load()?.longitude == location.coordinate.longitude)
      #expect(store.load()?.timestamp == location.timestamp)
    }
  }

  @Test
  func migratesLegacyDefaultsOnlyWhenSharedLocationIsMissing() {
    withStores { store, legacy in
      legacy.set(47.37, forKey: "lat")
      legacy.set(8.54, forKey: "long")

      let migrated = store.migrateLegacyLocation(from: legacy)
      #expect(migrated?.coordinate.latitude == 47.37)
      #expect(migrated?.coordinate.longitude == 8.54)

      legacy.set(1.0, forKey: "lat")
      let existing = store.migrateLegacyLocation(from: legacy)
      #expect(existing?.coordinate.latitude == 47.37)
    }
  }

  @Test
  func reloadsOnlyForFirstOrThreeKilometerMovement() {
    let origin = CLLocation(latitude: 47.37, longitude: 8.54)
    let nearby = CLLocation(latitude: 47.38, longitude: 8.54)
    let farAway = CLLocation(latitude: 47.41, longitude: 8.54)

    #expect(SharedLocationStore.requiresTimelineReload(from: nil, to: origin))
    #expect(!SharedLocationStore.requiresTimelineReload(from: origin, to: nearby))
    #expect(SharedLocationStore.requiresTimelineReload(from: origin, to: farAway))
  }

  private func withStores(_ body: (SharedLocationStore, UserDefaults) -> Void) {
    let sharedName = "DaylightTests.shared.\(UUID().uuidString)"
    let legacyName = "DaylightTests.legacy.\(UUID().uuidString)"
    let shared = UserDefaults(suiteName: sharedName)!
    let legacy = UserDefaults(suiteName: legacyName)!
    defer {
      shared.removePersistentDomain(forName: sharedName)
      legacy.removePersistentDomain(forName: legacyName)
    }
    body(SharedLocationStore(defaults: shared), legacy)
  }
}
