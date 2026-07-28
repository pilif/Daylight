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

  public var nauticalDawn: Date {
    sun.nauticalDawn
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

    return await DawnCalendarProvider.shared.hasCached(
      forSun: sun, calendar: self.calendar)
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

    let cal = DawnCalendarProvider.shared
    let dawnCalendar = await cal.getCalendar(
      forSun: sun, calendar: self.calendar
    )

    for times in dawnCalendar.times {
      if needDawnPreview && dawn == nil
        && calendar.startOfDay(for: times.dawn) > calendar.startOfDay(for: date)
        && times.dawn.secondsSinceMidnight(in: calendar)
          < self.sunrise.secondsSinceMidnight(in: calendar)
      {
        dawn = times.dawn
      }
      if needDuskPreview && dusk == nil
        && calendar.startOfDay(for: times.dusk) > calendar.startOfDay(for: date)
        && times.dusk.secondsSinceMidnight(in: calendar)
          > self.sunset.secondsSinceMidnight(in: calendar)
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

    let cal = DawnCalendarProvider.shared
    let dawnCalendar = await cal.getCalendar(
      forSun: sun,
      calendar: self.calendar)

    for times in dawnCalendar.times {
      if date < sun.civilDawn {
        if date > times.dawn {
          continue
        }
        if date.secondsSinceMidnight(in: calendar) >= times.dawn.secondsSinceMidnight(in: calendar)
        {
          return (dawn: times.dawn, dusk: nil)
        }
      } else if date > sun.civilDusk {
        if times.dusk < sun.civilDusk {
          continue
        }
        if date < times.dusk
          && date.secondsSinceMidnight(in: calendar)
            <= times.dusk.secondsSinceMidnight(in: calendar)
        {
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

    let secondsNow = now.secondsSinceMidnight(in: calendar)
    let secondsExtreme = extreme.secondsSinceMidnight(in: calendar)

    return Double(secondsExtreme - secondsNow)
  }

  public func eveningTimeSinceExtreme() async -> TimeInterval {
    let now = self.sun.civilDusk
    let extreme = await earliestSunset()

    let secondsNow = now.secondsSinceMidnight(in: calendar)
    let secondsExtreme = extreme.secondsSinceMidnight(in: calendar)

    return Double(secondsNow - secondsExtreme)
  }

  public func latestSunrise() async -> Date {
    let dawnCalendar = await DawnCalendarProvider.shared.getCalendar(
      forSun: sun,
      calendar: self.calendar
    )
    return dawnCalendar.latestDawn
  }

  public func earliestSunset() async -> Date {
    let dawnCalendar = await DawnCalendarProvider.shared.getCalendar(
      forSun: sun,
      calendar: self.calendar
    )
    return dawnCalendar.earliestDusk
  }
}

extension Date {
  public var secondsSinceMidnight: Int {
    secondsSinceMidnight(in: .current)
  }

  public func secondsSinceMidnight(in calendar: Calendar) -> Int {
    calendar.component(.hour, from: self) * 60 * 60
      + calendar.component(.minute, from: self) * 60
      + calendar.component(.second, from: self)
  }
}
