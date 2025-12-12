import CoreLocation
import Foundation
import SunKit

actor DawnCalendarProvider {
  private var cachedCalendars: [String: DawnCalendar] = [:]
  private var calculating: [String: Bool] = [:]

  func hasCached(
    forSun: Sun,
    calendar: Calendar = .current
  ) -> Bool {
    let id = cacheKey(forSun: forSun, calendar: calendar)
    return cachedCalendars[id] != nil
  }

  func getCalendar(
    forSun: Sun,
    calendar: Calendar = .current
  ) async -> DawnCalendar {
    let id = cacheKey(forSun: forSun, calendar: calendar)
    if let cal = cachedCalendars[id] {
      return cal
    }
    if calculating[id] != nil {
      var maxwait = 10
      while cachedCalendars[id] == nil && maxwait > 0 {
        do {
          try await Task.sleep(for: .seconds(3))
        } catch {
        }
        maxwait -= 1
      }
      if let cal = cachedCalendars[id] {
        return cal
      }
    }
    calculating[id] = true
    let calendar = await Task {
      var times: [(dawn: Date, dusk: Date)] = []
      var d = startDate(forSun: forSun)
      let endingAt = endDate(forSun: forSun)

      var latestDawn: Date? = nil
      var earliestDusk: Date? = nil

      while d < endingAt {
        let cd = calendar.date(byAdding: .day, value: 1, to: d)!
        let sunThen = Sun(location: forSun.location, timeZone: calendar.timeZone, date: cd)
        times.append((dawn: sunThen.civilDawn, dusk: sunThen.civilDusk))
        if latestDawn == nil
          || sunThen.civilDawn.secondsSinceMidnight > latestDawn!.secondsSinceMidnight
        {
          latestDawn = sunThen.civilDawn
        }
        if earliestDusk == nil
          || sunThen.civilDusk.secondsSinceMidnight < earliestDusk!.secondsSinceMidnight
        {
          earliestDusk = sunThen.civilDusk
        }
        d = cd
      }
      return DawnCalendar(
        times: times, earliestDusk: earliestDusk ?? forSun.date,
        latestDawn: latestDawn ?? forSun.date)
    }.value
    if cachedCalendars.count > 30 {
      cachedCalendars.removeAll()
    }
    cachedCalendars[id] = calendar
    calculating[id] = nil

    return calendar
  }

  // in case we take the december solstice for the beginning of the window
  // which we do to keep the amount of dates needing to be calculated as
  // small as possible, then subtract 21 days because normally, the earliest
  // sunset happens before the solstice
  private func startDate(forSun: Sun, calendar: Calendar = .current) -> Date {
    let date = forSun.date

    if date < forSun.decemberSolstice && date < forSun.juneSolstice {
      let lastYear = calendar.date(byAdding: DateComponents(year: -1), to: date)!
      let lastSun = Sun(location: forSun.location, timeZone: calendar.timeZone, date: lastYear)
      return calendar.date(byAdding: DateComponents(day: -21), to: lastSun.decemberSolstice) ?? date
    } else if date < forSun.decemberSolstice {
      return forSun.juneSolstice
    } else {
      return calendar.date(byAdding: DateComponents(day: -21), to: forSun.decemberSolstice) ?? date
    }
  }

  private func endDate(forSun: Sun, calendar: Calendar = .current) -> Date {
    let date = forSun.date

    if date < forSun.juneSolstice {
      return forSun.juneSolstice
    } else {
      // We're after this year's summer solstice, get next year's
      let nextYear = Calendar.current.date(byAdding: DateComponents(year: 1), to: date) ?? date
      let nextSun = Sun(location: forSun.location, timeZone: calendar.timeZone, date: nextYear)
      return nextSun.juneSolstice
    }

  }

  private func cacheKey(
    forSun: Sun,
    calendar: Calendar = .current
  ) -> String {
    let latRounded = (forSun.location.coordinate.latitude * 1000).rounded(.down) / 1000
    let longRounded = (forSun.location.coordinate.longitude * 1000).rounded(.down) / 1000

    let startingAtRounded = startDate(forSun: forSun).timeIntervalSince1970.rounded(.down)
    let endingAtRounded = endDate(forSun: forSun).timeIntervalSince1970.rounded(.down)
    let tz = calendar.timeZone.identifier

    return "\(latRounded),\(longRounded),\(startingAtRounded),\(endingAtRounded),\(tz)"
  }

  private init() {}

  static let shared = DawnCalendarProvider()
}
