import SwiftUI

struct SunView: View {
  let currentDate: Date

  @EnvironmentObject var locationViewModel: Location
  @State var displayDate: Date
  @State private var crownValue: Double = 0.0
  @State private var currentPreview: (dawn: Date?, dusk: Date?)? = nil
  @State private var currentDiffPreview: (dawn: Date?, dusk: Date?)? = nil
  @State private var loading: Bool = true
  @State private var morningDiff: TimeInterval? = nil
  @State private var eveningDiff: TimeInterval? = nil

  var body: some View {
    let calculator = SolarCalculator(
      forLocation: locationViewModel.lastSeenLocation ?? CLLocation(latitude: 0, longitude: 0),
      atDate: self.displayDate)

    VStack(alignment: .leading) {
      //      Text(displayDate.formatted(.iso8601))
      DateRow(
        currentDate: currentDate, displayDate: displayDate, offset: $crownValue, loading: $loading)
      SunRow(
        sunStyle: .sunrise,
        diff: morningDiff,
        diffPreview: currentDiffPreview?.dawn,
        absolute: calculator.sunrise,
        preview: currentPreview?.dawn,
        countdown: opinionatedCountdown(pure: calculator.countdown))
      Spacer()
      SunRow(
        sunStyle: .sunset,
        diff: eveningDiff,
        diffPreview: currentDiffPreview?.dusk,
        absolute: calculator.sunset,
        preview: currentPreview?.dusk,
        countdown: .none
      )
    }
    .onChange(of: crownValue) {
      self.displayDate = self.currentDate.addingTimeInterval(
        crownValue.rounded(.down) * 24 * 60 * 60)
    }
    .onChange(of: currentDate) {
      if crownValue.rounded(.down) == 0 {
        displayDate = currentDate
      }
    }
    .onChange(of: displayDate) {
      Task {
        loading = await !calculator.previewIsAvailable()
        currentPreview = await calculator.dawnPreview()
        currentDiffPreview = await calculator.sameDiffPreview()
        morningDiff = await calculator.morningTimeSinceExtreme()
        eveningDiff = await calculator.eveningTimeSinceExtreme()
        loading = false
      }
    }
    .focusable()
    .digitalCrownRotation(
      $crownValue, from: -30, through: 30, by: 1, sensitivity: .low, isContinuous: false,
      isHapticFeedbackEnabled: true)
  }

  func opinionatedCountdown(pure: TwilightCountdown) -> TwilightCountdown {
    switch pure {
    case .none:
      return .none
    case .civil(let ti), .nautical(let ti):
      return ti > 60 * 60 ? .none : pure
    }
  }

  public init(currentDate: Date) {
    self.currentDate = currentDate
    self.displayDate = currentDate
  }
}
