import CoreLocation
import SunKit

struct SolarCalculator {
  private let date: Date
  private let sun: Sun
  private let sunAtSolstice: Sun
  private let calendar: Calendar

  public init(
    forLocation location: CLLocation, atDate date: Date, calendar: Calendar = Calendar.current
  ) {
    self.sun = Sun(location: location, timeZone: calendar.timeZone, date: date)
    self.date = date
    self.calendar = calendar

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
  }

  public var pastSolstice: Date {
    sunAtSolstice.date
  }

  public var sunrise: Date {
    sun.civilDawn
  }

  public var sunset: Date {
    sun.civilDusk
  }

  public func dawnPreview() async -> Date? {
    if date > sun.civilDawn {
      return nil
    }

    let cal = DawnCalendar.shared
    let dawnDates = await cal.getCalendar(
      forLocation: sun.location, startingAt: pastSolstice, endingAt: sun.juneSolstice,
      calendar: self.calendar)
    for dawnDate in dawnDates {
      if date > dawnDate {
        continue
      }
      if date.secondsSinceMidnight >= dawnDate.secondsSinceMidnight {
        return dawnDate
      }
    }
    return nil
  }

  public var morningTimeSinceSolistice: TimeInterval {
    let now = self.sun.civilDawn
    let then = self.sunAtSolstice.civilDawn

    let secondsNow = now.secondsSinceMidnight
    let secondsThen = then.secondsSinceMidnight

    return Double(secondsThen - secondsNow)
  }

  public var eveningTimeSinceSolistice: TimeInterval {
    let now = self.sun.civilDusk
    let then = self.sunAtSolstice.civilDusk

    let secondsNow = now.secondsSinceMidnight
    let secondsThen = then.secondsSinceMidnight

    return Double(secondsNow - secondsThen)
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
