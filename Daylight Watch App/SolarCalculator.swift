import CoreLocation
import SunKit

struct SolarCalculator {
  private let date: Date
  private let sun: Sun
  private let sunAtSolstice: Sun
  private let sunAtNextSummerSolstice: Sun
  private let calendar: Calendar

  public init(
    forLocation location: CLLocation, atDate date: Date, calendar: Calendar = Calendar.current
  ) {
    self.sun = Sun(location: location, timeZone: calendar.timeZone, date: date)
    self.date = date
    self.calendar = calendar

    // Calculate past solstice (for time-since-solstice calculations)
    if date < sun.decemberSolstice && date < sun.juneSolstice {
      let lastYear = Calendar.current.date(byAdding: DateComponents(year: -1), to: date)!

      let lastSun = Sun(location: location, timeZone: calendar.timeZone, date: lastYear)

      sunAtSolstice = Sun(
        location: location, timeZone: calendar.timeZone, date: lastSun.decemberSolstice)
    } else if date < sun.decemberSolstice {
      sunAtSolstice = Sun(
        location: location, timeZone: calendar.timeZone, date: sun.juneSolstice)
    } else {
      sunAtSolstice = Sun(
        location: location, timeZone: calendar.timeZone, date: sun.decemberSolstice)
    }

    // Calculate next summer solstice (for preview calculations)
    if date < sun.juneSolstice {
      // We're before this year's summer solstice
      sunAtNextSummerSolstice = Sun(
        location: location, timeZone: calendar.timeZone, date: sun.juneSolstice)
    } else {
      // We're after this year's summer solstice, get next year's
      let nextYear = Calendar.current.date(byAdding: DateComponents(year: 1), to: date)!
      let nextSun = Sun(location: location, timeZone: calendar.timeZone, date: nextYear)
      sunAtNextSummerSolstice = Sun(
        location: location, timeZone: calendar.timeZone, date: nextSun.juneSolstice)
    }
  }

  public var pastSolstice: Date {
    sunAtSolstice.date
  }

  public var nextSummerSolstice: Date {
    sunAtNextSummerSolstice.date
  }

  public var sunrise: Date {
    sun.civilDawn
  }

  public var sunset: Date {
    sun.civilDusk
  }

  public var countdown: TwilightCountdown {
    if date > sun.civilDawn {
      return .none
    }
    if date > sun.nauticalDawn {
      return .civil(in: sun.civilDawn.timeIntervalSince(date))
    }
    return .nautical(in: sun.nauticalDawn.timeIntervalSince(date))
  }

  public func previewIsAvailable() async -> Bool {
    // if we don't really have a preview to show, we don't
    // need to use the calendar and thus we can assume a dawn
    // preview to be immediately available
    if !previewIsNeeded() {
      return true
    }

    return await DawnCalendar.shared.hasCached(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: nextSummerSolstice,
      calendar: self.calendar)
  }

  public func sameDiffPreview() async -> (dawn: Date?, dusk: Date?) {
    var dawn: Date?
    var dusk: Date?

    let latestSunrise = await latestSunrise()
    let earliestSunset = await earliestSunset()

    let needDawnPreview = date < latestSunrise
    let needDuskPreview = date < earliestSunset

    if !needDawnPreview && !needDuskPreview {
      return (dawn: nil, dusk: nil)
    }

    let cal = DawnCalendar.shared
    let dawnCalendar = await cal.getCalendar(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: nextSummerSolstice,
      calendar: self.calendar)

    for times in dawnCalendar {
      if needDawnPreview && dawn == nil
        && calendar.startOfDay(for: times.dawn) > calendar.startOfDay(for: date)
        && times.dawn.secondsSinceMidnight < self.sunrise.secondsSinceMidnight
      {
        dawn = times.dawn
      }
      if needDuskPreview && dusk == nil
        && calendar.startOfDay(for: times.dusk) > calendar.startOfDay(for: date)
        && times.dusk.secondsSinceMidnight > self.sunset.secondsSinceMidnight
      {
        dusk = times.dusk
      }
      if dusk != nil && dawn != nil {
        break
      }
    }

    let dawnPreview = needDawnPreview ? dawn : nil
    let duskPreview = needDuskPreview ? dusk : nil

    return (dawn: dawnPreview, dusk: duskPreview)
  }

  public func dawnPreview() async -> (dawn: Date?, dusk: Date?) {

    if !previewIsNeeded() {
      return (dawn: nil, dusk: nil)
    }

    let cal = DawnCalendar.shared
    let dawnCalendar = await cal.getCalendar(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: nextSummerSolstice,
      calendar: self.calendar)

    for times in dawnCalendar {
      if date < sun.civilDawn {
        if date > times.dawn {
          continue
        }
        if date.secondsSinceMidnight >= times.dawn.secondsSinceMidnight {
          return (dawn: times.dawn, dusk: nil)
        }
      } else if date > sun.civilDusk {
        if times.dusk < sun.civilDusk {
          continue
        }
        if date < times.dusk && date.secondsSinceMidnight <= times.dusk.secondsSinceMidnight {
          return (dawn: nil, dusk: times.dusk)
        }
      }
    }
    return (dawn: nil, dusk: nil)
  }

  private func previewIsNeeded() -> Bool {
    return (date <= sun.civilDawn || date >= sun.civilDusk)
  }

  public func morningTimeSinceExtreme() async -> TimeInterval {
    let now = self.sun.civilDawn
    let extreme = await latestSunrise()

    let secondsNow = now.secondsSinceMidnight
    let secondsExtreme = extreme.secondsSinceMidnight

    return Double(secondsExtreme - secondsNow)
  }

  public func eveningTimeSinceExtreme() async -> TimeInterval {
    let now = self.sun.civilDusk
    let extreme = await earliestSunset()

    let secondsNow = now.secondsSinceMidnight
    let secondsExtreme = extreme.secondsSinceMidnight

    return Double(secondsNow - secondsExtreme)
  }

  public func latestSunrise() async -> Date {
    let dawnCalendar = await DawnCalendar.shared.getCalendar(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: nextSummerSolstice,
      calendar: self.calendar)

    var latestDawn: Date?
    var latestSeconds = 0
    let decemberSolstice = getDecemberSolstice()
    let earliest = calendar.date(byAdding: .day, value: -30, to: decemberSolstice)
    let latest = calendar.date(byAdding: .day, value: +30, to: decemberSolstice)

    if let earliest, let latest {
      for times in dawnCalendar {
        if times.dawn < earliest {
          continue
        }
        if times.dawn > latest {
          break
        }
        let seconds = times.dawn.secondsSinceMidnight
        if latestDawn == nil || seconds > latestSeconds {
          latestDawn = times.dawn
          latestSeconds = seconds
        }
      }
    }

    return latestDawn ?? sun.civilDawn
  }

  public func earliestSunset() async -> Date {
    let dawnCalendar = await DawnCalendar.shared.getCalendar(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: nextSummerSolstice,
      calendar: self.calendar)

    var earliestDusk: Date?
    var earliestSeconds = Int.max
    let decemberSolstice = getDecemberSolstice()
    let earliest = calendar.date(byAdding: .day, value: -30, to: decemberSolstice)
    let latest = calendar.date(byAdding: .day, value: +30, to: decemberSolstice)
    if let earliest, let latest {
      for times in dawnCalendar {
        if times.dawn < earliest {
          continue
        }
        if times.dawn > latest {
          break
        }

        let seconds = times.dusk.secondsSinceMidnight
        if earliestDusk == nil || seconds < earliestSeconds {
          earliestDusk = times.dusk
          earliestSeconds = seconds
        }
      }
    }

    return earliestDusk ?? sun.civilDusk
  }

  private func getDecemberSolstice() -> Date {
    // If sunAtSolstice is already December solstice, use it
    // Otherwise (it's June), we need the previous December
    let solsticeMonth = calendar.component(.month, from: sunAtSolstice.date)
    if solsticeMonth == 12 {
      return sunAtSolstice.date
    } else {
      return sunAtSolstice.decemberSolstice
    }
  }

}

extension Date {
  public var secondsSinceMidnight: Int {
    let cal = Calendar.current
    return cal.component(.hour, from: self) * 60 * 60
      + cal.component(.minute, from: self) * 60
      + cal.component(.second, from: self)
  }
}
