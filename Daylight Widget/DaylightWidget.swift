import CoreLocation
import SwiftUI
import WidgetKit

struct DaylightWidgetEntry: TimelineEntry {
  let date: Date
  let content: SunTransitionContent?

  var relevance: TimelineEntryRelevance? {
    guard let countdown = content?.countdown else {
      return nil
    }
    return TimelineEntryRelevance(
      score: 100,
      duration: max(0, countdown.target.timeIntervalSince(date)))
  }
}

final class DaylightWidgetProvider: TimelineProvider {
  private var locationResolver: WidgetLocationResolver?

  func placeholder(in context: Context) -> DaylightWidgetEntry {
    .previewSunrise
  }

  func getSnapshot(in context: Context, completion: @escaping (DaylightWidgetEntry) -> Void) {
    if context.isPreview {
      completion(.previewSunrise)
      return
    }

    guard let location = SharedLocationStore.shared.load()?.location else {
      completion(DaylightWidgetEntry(date: .now, content: nil))
      return
    }
    Task {
      let date = Date.now
      let content = await SunTransitionSchedule.content(for: location, at: date)
      completion(DaylightWidgetEntry(date: date, content: content))
    }
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<DaylightWidgetEntry>) -> Void
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      let resolver = WidgetLocationResolver()
      locationResolver = resolver
      resolver.resolve { [weak self] freshLocation in
        self?.locationResolver = nil
        if let freshLocation {
          SharedLocationStore.shared.save(freshLocation)
        }
        let location = freshLocation ?? SharedLocationStore.shared.load()?.location
        Task {
          completion(await Self.timeline(for: location, startingAt: .now))
        }
      }
    }
  }

  private static func timeline(
    for location: CLLocation?, startingAt start: Date, calendar: Calendar = .current
  ) async -> Timeline<DaylightWidgetEntry> {
    guard let location else {
      return Timeline(
        entries: [DaylightWidgetEntry(date: start, content: nil)],
        policy: .after(start.addingTimeInterval(60 * 60)))
    }

    var entries: [DaylightWidgetEntry] = []
    let dates = SunTransitionSchedule.boundaryDates(
      for: location, startingAt: start, calendar: calendar)
    for date in dates {
      let content = await SunTransitionSchedule.content(
        for: location, at: date, calendar: calendar)
      entries.append(DaylightWidgetEntry(date: date, content: content))
    }
    return Timeline(entries: entries, policy: .atEnd)
  }
}

private final class WidgetLocationResolver: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var completion: ((CLLocation?) -> Void)?
  private var timeout: DispatchWorkItem?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
  }

  func resolve(completion: @escaping (CLLocation?) -> Void) {
    self.completion = completion
    guard
      manager.authorizationStatus == .authorizedAlways
        || manager.authorizationStatus == .authorizedWhenInUse
    else {
      finish(with: nil)
      return
    }

    let timeout = DispatchWorkItem { [weak self] in
      self?.finish(with: nil)
    }
    self.timeout = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeout)
    manager.requestLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    finish(with: locations.last)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finish(with: nil)
  }

  private func finish(with location: CLLocation?) {
    guard let completion else {
      return
    }
    self.completion = nil
    timeout?.cancel()
    timeout = nil
    completion(location)
  }
}

struct NextSunTransitionWidgetView: View {
  let entry: DaylightWidgetEntry

  var body: some View {
    Group {
      if let content = entry.content {
        transition(content)
      } else {
        unavailable
      }
    }
    .containerBackground(for: .widget) {
      Color.clear
    }
  }

  private func transition(_ content: SunTransitionContent) -> some View {
    HStack(spacing: 8) {
      Image(systemName: content.style == .sunrise ? "sunrise.fill" : "sunset.fill")
        .symbolRenderingMode(.multicolor)
        .font(.system(size: 36))
        .frame(width: 44)
        .widgetAccentable()

      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 2) {
        if let countdown = content.countdown {
          HStack(spacing: 3) {
            Text("\(countdown.phase.label) in")
            Text(
              timerInterval: countdown.startsAt...countdown.target,
              pauseTime: countdown.target,
              countsDown: true,
              showsHours: true
            )
            .monospacedDigit()
          }
          .font(.caption)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
        } else {
          Text(
            SunTransitionFormatting.difference(
              content.difference,
              absolute: content.absolute,
              previewDate: content.differencePreview)
          )
          .font(.headline)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
        }

        if let preview = content.preview {
          HStack(spacing: 3) {
            Image(systemName: "sparkles")
            Text(SunTransitionFormatting.preview(absolute: content.absolute, preview: preview))
          }
          .font(.caption2)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        } else {
          Text(SunTransitionFormatting.clockTime(content.absolute))
            .font(.caption2)
        }
      }
    }
  }

  private var unavailable: some View {
    HStack(spacing: 8) {
      Image(systemName: "location.slash.fill")
        .font(.title2)
      Text("Open Daylight for location")
        .font(.caption)
        .lineLimit(2)
    }
  }
}

@main
struct NextSunTransitionWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: DaylightWidgetKind.nextSunTransition,
      provider: DaylightWidgetProvider()
    ) { entry in
      NextSunTransitionWidgetView(entry: entry)
    }
    .configurationDisplayName("Next Sun Transition")
    .description("Shows the next sunrise or sunset and its final-hour countdown.")
    .supportedFamilies([.accessoryRectangular])
  }
}

extension DaylightWidgetEntry {
  fileprivate static let previewSunrise = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_885_800),
    content: SunTransitionContent(
      style: .sunrise,
      absolute: Date(timeIntervalSince1970: 1_735_910_400),
      difference: 12 * 60 + 14,
      differencePreview: nil,
      preview: nil,
      countdown: nil))

  fileprivate static let previewCivilCountdown = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_908_600),
    content: SunTransitionContent(
      style: .sunrise,
      absolute: Date(timeIntervalSince1970: 1_735_910_400),
      difference: 12 * 60 + 14,
      differencePreview: nil,
      preview: nil,
      countdown: SunTransitionCountdown(
        phase: .civilDawn,
        startsAt: Date(timeIntervalSince1970: 1_735_908_000),
        target: Date(timeIntervalSince1970: 1_735_910_400))))

  fileprivate static let previewNauticalCountdown = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_906_800),
    content: SunTransitionContent(
      style: .sunrise,
      absolute: Date(timeIntervalSince1970: 1_735_910_400),
      difference: 12 * 60 + 14,
      differencePreview: nil,
      preview: nil,
      countdown: SunTransitionCountdown(
        phase: .nauticalDawn,
        startsAt: Date(timeIntervalSince1970: 1_735_905_600),
        target: Date(timeIntervalSince1970: 1_735_908_000))))

  fileprivate static let previewSunset = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_930_800),
    content: SunTransitionContent(
      style: .sunset,
      absolute: Date(timeIntervalSince1970: 1_735_944_000),
      difference: 8 * 60 + 42,
      differencePreview: nil,
      preview: nil,
      countdown: nil))

  fileprivate static let previewDuskCountdown = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_942_200),
    content: SunTransitionContent(
      style: .sunset,
      absolute: Date(timeIntervalSince1970: 1_735_944_000),
      difference: 8 * 60 + 42,
      differencePreview: nil,
      preview: nil,
      countdown: SunTransitionCountdown(
        phase: .civilDusk,
        startsAt: Date(timeIntervalSince1970: 1_735_940_400),
        target: Date(timeIntervalSince1970: 1_735_944_000))))

  fileprivate static let previewFutureMatch = DaylightWidgetEntry(
    date: Date(timeIntervalSince1970: 1_735_885_800),
    content: SunTransitionContent(
      style: .sunrise,
      absolute: Date(timeIntervalSince1970: 1_735_910_400),
      difference: 12 * 60 + 14,
      differencePreview: nil,
      preview: Date(timeIntervalSince1970: 1_740_230_400),
      countdown: nil))
}

#Preview("Sunrise", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewSunrise
}

#Preview("Civil countdown", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewCivilCountdown
}

#Preview("Nautical countdown", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewNauticalCountdown
}

#Preview("Sunset", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewSunset
}

#Preview("Dusk countdown", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewDuskCountdown
}

#Preview("Future match", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry.previewFutureMatch
}

#Preview("No location", as: .accessoryRectangular) {
  NextSunTransitionWidget()
} timeline: {
  DaylightWidgetEntry(date: .now, content: nil)
}
