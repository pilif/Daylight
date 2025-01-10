import CoreLocation
import Foundation
import Testing

@testable import Daylight_Watch_App

@Suite
struct SolarCalculatorTests {

  @Test(
    arguments: zip(
      [
        // (past sunrise. expect no preview)
        "2025-01-09 08:28:45+01",

        // (before sunrise. expected dawn on march 2nd to happen before 6:35)
        "2025-01-09 06:35:22+01",

        // (sun will never rise this early. expect no preview)
        "2025-01-09 01:35:22+01",
      ], [nil, "2025-03-02 06:34:25+01", nil]))

  func nextDayWhenSunIsUp(currentDate: Date, expectedOutput: Date?) async {
    let location = CLLocation(latitude: 47.35911111, longitude: 8.51980556)
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
    calendar.locale = Locale(identifier: "de_CH")
    let calc = SolarCalculator(forLocation: location, atDate: currentDate, calendar: calendar)
    let dawnPreview = await calc.nextDayWhenSunIsUp()

    #expect(expectedOutput == dawnPreview)
  }

}
