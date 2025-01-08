import SwiftUI

struct SunView: View {
  @EnvironmentObject var locationViewModel: Location
  @State var displayDate: Date = Date()
  @State var currentDate: Date = Date()
  @State private var crownValue = 0.0

  var body: some View {
    let calculator = SolarCalculator(
      forLocation: locationViewModel.lastSeenLocation ?? CLLocation(latitude: 0, longitude: 0),
      atDate: self.displayDate)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    VStack {
      SunRow(
        sunStyle: .sunrise, diff: calculator.morningTimeSinceSolistice,
        absolute: calculator.sunrise, preview: calculator.nextDayWhenSunIsUp)
      Spacer()
      SunRow(
        sunStyle: .sunset, diff: calculator.eveningTimeSinceSolistice, absolute: calculator.sunset,
        preview: nil)
      //            Text("Crown Value: \(crownValue) sr=\(calculator.sunrise.formatted(.iso8601))")
    }
    .onReceive(timer) { date in
      self.currentDate = date
      if crownValue == 0.0 {
        self.displayDate = date
      }
    }
    .onChange(of: crownValue) {
      self.displayDate = self.currentDate.addingTimeInterval(
        crownValue.rounded(.down) * 24 * 60 * 60)
    }
    .focusable()
    .digitalCrownRotation(
      $crownValue, from: -30, through: 30, by: 1, sensitivity: .low, isContinuous: false,
      isHapticFeedbackEnabled: true)
  }
}
