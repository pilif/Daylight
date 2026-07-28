import CoreLocation
import Foundation
import Testing

@testable import Daylight_Watch_App

@Suite(.serialized)
struct SunTransitionTests {
  private let location = CLLocation(latitude: 47.35911111, longitude: 8.51980556)

  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
    calendar.locale = Locale(identifier: "en_CH")
    return calendar
  }

  @Test
  func selectsSunriseThenSunsetThenTomorrowsSunrise() async {
    let reference: Date = "2025-01-09 12:00:00+01"
    let calculator = SolarCalculator(
      forLocation: location, atDate: calendar.startOfDay(for: reference), calendar: calendar)

    let beforeDawn = await SunTransitionSchedule.content(
      for: location, at: calculator.sunrise.addingTimeInterval(-1), calendar: calendar)
    #expect(beforeDawn.style == .sunrise)
    #expect(beforeDawn.absolute == calculator.sunrise)

    let atDawn = await SunTransitionSchedule.content(
      for: location, at: calculator.sunrise, calendar: calendar)
    #expect(atDawn.style == .sunset)
    #expect(atDawn.absolute == calculator.sunset)

    let beforeDusk = await SunTransitionSchedule.content(
      for: location, at: calculator.sunset.addingTimeInterval(-1), calendar: calendar)
    #expect(beforeDusk.style == .sunset)

    let atDusk = await SunTransitionSchedule.content(
      for: location, at: calculator.sunset, calendar: calendar)
    let tomorrow = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: reference))!
    let tomorrowCalculator = SolarCalculator(
      forLocation: location, atDate: tomorrow, calendar: calendar)
    #expect(atDusk.style == .sunrise)
    #expect(atDusk.absolute == tomorrowCalculator.sunrise)
  }

  @Test
  func appliesTheOpinionatedCountdownBoundaries() async {
    let reference: Date = "2025-01-09 12:00:00+01"
    let calculator = SolarCalculator(
      forLocation: location, atDate: calendar.startOfDay(for: reference), calendar: calendar)
    let nauticalStart = calculator.nauticalDawn.addingTimeInterval(
      -SunTransitionSchedule.countdownDuration)

    let beforeNauticalWindow = await SunTransitionSchedule.content(
      for: location, at: nauticalStart.addingTimeInterval(-1), calendar: calendar)
    #expect(beforeNauticalWindow.countdown == nil)

    let atNauticalWindow = await SunTransitionSchedule.content(
      for: location, at: nauticalStart, calendar: calendar)
    #expect(atNauticalWindow.countdown?.phase == .nauticalDawn)
    #expect(atNauticalWindow.countdown?.target == calculator.nauticalDawn)

    let atNauticalDawn = await SunTransitionSchedule.content(
      for: location, at: calculator.nauticalDawn, calendar: calendar)
    #expect(atNauticalDawn.countdown?.phase == .civilDawn)
    #expect(atNauticalDawn.countdown?.target == calculator.sunrise)

    let duskStart = calculator.sunset.addingTimeInterval(
      -SunTransitionSchedule.countdownDuration)
    let atDuskWindow = await SunTransitionSchedule.content(
      for: location, at: duskStart, calendar: calendar)
    #expect(atDuskWindow.countdown?.phase == .civilDusk)
    #expect(atDuskWindow.countdown?.target == calculator.sunset)

    let atDusk = await SunTransitionSchedule.content(
      for: location, at: calculator.sunset, calendar: calendar)
    #expect(atDusk.style == .sunrise)
    #expect(atDusk.countdown == nil)
  }

  @Test
  func producesAUniqueChronologicalSevenDayTimelineAcrossDST() {
    let start: Date = "2025-03-28 12:00:00+01"
    let dates = SunTransitionSchedule.boundaryDates(
      for: location, startingAt: start, calendar: calendar)
    let end = calendar.date(byAdding: .day, value: 7, to: start)!

    #expect(dates.first == start)
    #expect(dates == dates.sorted())
    #expect(Set(dates).count == dates.count)
    #expect(dates.allSatisfy { $0 >= start && $0 <= end })
    #expect(dates.count > 25)
    #expect(end.timeIntervalSince(start) == 7 * 24 * 60 * 60 - 60 * 60)
  }
}
