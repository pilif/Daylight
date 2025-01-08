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
      let lastYear = Calendar.current.date(byAdding: DateComponents(year: -1), to: date)!

      let lastSun = Sun(location: location, timeZone: Calendar.current.timeZone, date: lastYear)

      sunAtSolstice = Sun(
        location: location, timeZone: Calendar.current.timeZone, date: lastSun.decemberSolstice)
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

  public var nextDayWhenSunIsUp: Date? {
    if date > sun.civilDawn {
      return nil
    }

    var d: Date = date
    let c = Calendar.current
    while d < sun.juneSolstice {
      if let cd = c.date(byAdding: .day, value: 1, to: d) {
        d = cd
        if d > sun.civilDawn { return d }
      } else {
        return nil
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
