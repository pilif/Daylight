import CoreLocation
import Foundation

enum SunTransitionCountdownPhase: Equatable, Sendable {
  case nauticalDawn
  case civilDawn
  case civilDusk

  var label: String {
    switch self {
    case .nauticalDawn:
      "Nautical"
    case .civilDawn, .civilDusk:
      "Civil"
    }
  }
}

struct SunTransitionCountdown: Equatable, Sendable {
  let phase: SunTransitionCountdownPhase
  let startsAt: Date
  let target: Date
}

struct SunTransitionContent: Equatable, Sendable {
  let style: SunStyle
  let absolute: Date
  let difference: TimeInterval?
  let differencePreview: Date?
  let preview: Date?
  let countdown: SunTransitionCountdown?
}

enum SunTransitionSchedule {
  static let countdownDuration: TimeInterval = 60 * 60

  static func content(
    for location: CLLocation,
    at date: Date,
    calendar: Calendar = .current
  ) async -> SunTransitionContent {
    let calculationDate = calendar.startOfDay(for: date)
    let currentCalculator = SolarCalculator(
      forLocation: location, atDate: calculationDate, calendar: calendar)

    if date < currentCalculator.sunrise {
      return await sunriseContent(calculator: currentCalculator, at: date)
    }
    if date < currentCalculator.sunset {
      return await sunsetContent(calculator: currentCalculator, at: date)
    }

    let tomorrow =
      calendar.date(
        byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    let tomorrowCalculator = SolarCalculator(
      forLocation: location, atDate: tomorrow, calendar: calendar)
    return await sunriseContent(calculator: tomorrowCalculator, at: date)
  }

  static func boundaryDates(
    for location: CLLocation,
    startingAt start: Date,
    days: Int = 7,
    calendar: Calendar = .current
  ) -> [Date] {
    guard days > 0,
      let end = calendar.date(byAdding: .day, value: days, to: start)
    else {
      return [start]
    }

    var dates = Set([start])
    var day = calendar.startOfDay(for: start)
    let lastDay = calendar.startOfDay(for: end)

    while day <= lastDay {
      let calculator = SolarCalculator(forLocation: location, atDate: day, calendar: calendar)
      let candidates = [
        calculator.nauticalDawn.addingTimeInterval(-countdownDuration),
        calculator.nauticalDawn,
        calculator.sunrise,
        calculator.sunset.addingTimeInterval(-countdownDuration),
        calculator.sunset,
      ]
      for candidate in candidates where candidate > start && candidate <= end {
        dates.insert(candidate)
      }
      guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
        break
      }
      day = nextDay
    }

    return dates.sorted()
  }

  private static func sunriseContent(
    calculator: SolarCalculator,
    at date: Date
  ) async -> SunTransitionContent {
    let countdown: SunTransitionCountdown?
    let nauticalStart = calculator.nauticalDawn.addingTimeInterval(-countdownDuration)
    if date >= nauticalStart && date < calculator.nauticalDawn {
      countdown = SunTransitionCountdown(
        phase: .nauticalDawn, startsAt: nauticalStart, target: calculator.nauticalDawn)
    } else if date >= calculator.nauticalDawn && date < calculator.sunrise {
      countdown = SunTransitionCountdown(
        phase: .civilDawn, startsAt: calculator.nauticalDawn, target: calculator.sunrise)
    } else {
      countdown = nil
    }

    let preview = await calculator.dawnPreview()
    let differencePreview = await calculator.sameDiffPreview()
    return SunTransitionContent(
      style: .sunrise,
      absolute: calculator.sunrise,
      difference: await calculator.morningTimeSinceExtreme(),
      differencePreview: differencePreview.dawn,
      preview: preview.dawn,
      countdown: countdown)
  }

  private static func sunsetContent(
    calculator: SolarCalculator,
    at date: Date
  ) async -> SunTransitionContent {
    let countdownStart = calculator.sunset.addingTimeInterval(-countdownDuration)
    let countdown =
      date >= countdownStart && date < calculator.sunset
      ? SunTransitionCountdown(
        phase: .civilDusk, startsAt: countdownStart, target: calculator.sunset)
      : nil

    let preview = await calculator.dawnPreview()
    let differencePreview = await calculator.sameDiffPreview()
    return SunTransitionContent(
      style: .sunset,
      absolute: calculator.sunset,
      difference: await calculator.eveningTimeSinceExtreme(),
      differencePreview: differencePreview.dusk,
      preview: preview.dusk,
      countdown: countdown)
  }
}
