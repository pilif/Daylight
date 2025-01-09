import CoreLocation
import Foundation
import Testing

@testable import Daylight_Watch_App

@Suite
struct SolarCalculatorTests {

  @Test(
    arguments: zip(
      [
        // 2025-01-09 08:28:45+01 (past sunrise. expect no preview)
        Date(timeIntervalSince1970: 1_736_407_725),

        // 2025-01-09 06:35:22+01 (before sunrise. expected dawn on march 2nd to happen before 6:35)
        Date(timeIntervalSince1970: 1_736_400_922),

        // 2025-01-09 00:35:22+01 (sun will never rise this early. expect no preview)
        Date(timeIntervalSince1970: 1_736_379_322),
      ], [nil, Date(timeIntervalSince1970: 1_740_893_722), nil]))
  func nextDayWhenSunIsUp(currentDate: Date, expectedOutput: Date?) {
    let location = CLLocation(latitude: 47.35911111, longitude: 8.51980556)
    let calc = SolarCalculator(forLocation: location, atDate: currentDate)

    #expect(expectedOutput == calc.nextDayWhenSunIsUp)
  }

}
