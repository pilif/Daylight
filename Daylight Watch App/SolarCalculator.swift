import CoreLocation
import SunKit

struct SolarCalculator {
  private let date: Date
  private let sun: Sun
  private let sunAtSolstice: Sun

  public init(forLocation location: CLLocation, atDate date: Date) {
    self.sun = Sun(location: location, timeZone: Calendar.current.timeZone, date: date)
    self.date = date

    if date < sun.decemberSolstice && date < sun.juneSolstice {
      let last_year = Calendar.current.date(byAdding: DateComponents(year: -1), to: date)!

      let last_sun = Sun(location: location, timeZone: Calendar.current.timeZone, date: last_year)

      sunAtSolstice = Sun(
        location: location, timeZone: Calendar.current.timeZone, date: last_sun.decemberSolstice)
    } else if date < sun.decemberSolstice {
      sunAtSolstice = Sun(
        location: location, timeZone: Calendar.current.timeZone, date: sun.juneSolstice)
    } else {
      sunAtSolstice = Sun(
        location: location, timeZone: Calendar.current.timeZone, date: sun.decemberSolstice)
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

  public var morningTimeSinceSolistice: TimeInterval {
    let cal = Calendar.current

    let now = self.sun.civilDawn
    let then = self.sunAtSolstice.civilDawn

    let seconds_now = now.secondsSinceMidnight
    let seconds_then = then.secondsSinceMidnight

    return Double(seconds_then - seconds_now)
  }

  public var eveningTimeSinceSolistice: TimeInterval {
    let now = self.sun.civilDusk
    let then = self.sunAtSolstice.civilDusk

    let seconds_now = now.secondsSinceMidnight
    let seconds_then = then.secondsSinceMidnight

    return Double(seconds_now - seconds_then)
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
