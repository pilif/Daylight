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

    let seconds_now =
      cal.component(.hour, from: now) * 60 * 60
      + cal.component(.minute, from: now) * 60
      + cal.component(.second, from: now)

    let seconds_then =
      cal.component(.hour, from: then) * 60 * 60
      + cal.component(.minute, from: then) * 60
      + cal.component(.second, from: then)

    return Double(seconds_then - seconds_now)
  }

  public var eveningTimeSinceSolistice: TimeInterval {
    let cal = Calendar.current

    let now = self.sun.civilDusk
    let then = self.sunAtSolstice.civilDusk

    let seconds_now =
      cal.component(.hour, from: now) * 60 * 60
      + cal.component(.minute, from: now) * 60
      + cal.component(.second, from: now)

    let seconds_then =
      cal.component(.hour, from: then) * 60 * 60
      + cal.component(.minute, from: then) * 60
      + cal.component(.second, from: then)

    return Double(seconds_now - seconds_then)
  }

}
