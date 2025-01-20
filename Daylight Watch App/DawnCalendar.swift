import CoreLocation
import Foundation
import SunKit

actor DawnCalendar {
  private var cachedCalendars: [String: [(dawn: Date, dusk: Date)]] = [:]

  func hasCached(
    forLocation: CLLocation, startingAt: Date,
    endingAt: Date, calendar: Calendar = .current
  ) -> Bool {
    let id = cacheKey(
      forLocation: forLocation, startingAt: startingAt, endingAt: endingAt, calendar: calendar)
    return cachedCalendars[id] != nil
  }

  func getCalendar(
    forLocation: CLLocation, startingAt: Date,
    endingAt: Date, calendar: Calendar = .current
  ) async -> [(dawn: Date, dusk: Date)] {
    let id = cacheKey(
      forLocation: forLocation, startingAt: startingAt, endingAt: endingAt, calendar: calendar)
    if let cal = cachedCalendars[id] {
      return cal
    }
    let calendar = await Task {
      var dates: [(dawn: Date, dusk: Date)] = []
      let loc = CLLocation(
        latitude: forLocation.coordinate.latitude, longitude: forLocation.coordinate.longitude)
      var d = startingAt
      while d < endingAt {
        let cd = calendar.date(byAdding: .day, value: 1, to: d)!
        let sunThen = Sun(location: loc, timeZone: calendar.timeZone, date: cd)
        dates.append((dawn: sunThen.civilDawn, dusk: sunThen.civilDusk))
        d = cd
      }
      return dates
    }.value
    if cachedCalendars.count > 30 {
      cachedCalendars.removeAll()
    }
    cachedCalendars[id] = calendar
    return calendar
  }

  private func cacheKey(
    forLocation: CLLocation, startingAt: Date,
    endingAt: Date, calendar: Calendar = .current
  ) -> String {
    let latRounded = (forLocation.coordinate.latitude * 1000).rounded(.down) / 1000
    let longRounded = (forLocation.coordinate.longitude * 1000).rounded(.down) / 1000

    let startingAtRounded = startingAt.timeIntervalSince1970.rounded(.down)
    let endingAtRounded = endingAt.timeIntervalSince1970.rounded(.down)
    let tz = calendar.timeZone.identifier

    return "\(latRounded),\(longRounded),\(startingAtRounded),\(endingAtRounded),\(tz)"
  }

  private init() {}

  static let shared = DawnCalendar()
}
