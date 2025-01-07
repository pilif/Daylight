import SwiftUI

struct SunView: View {
    @EnvironmentObject var locationViewModel: Location
    @State var date: Date = Date()
        
    var body: some View {
        let calculator = SolarCalculator(forLocation: locationViewModel.lastSeenLocation ?? CLLocation(latitude: 0, longitude: 0), atDate: self.date)
        
        VStack() {
            SunRow(sunStyle: .sunrise, diff: calculator.morningTimeSinceSolistice, absolute: calculator.sunrise)
            Spacer()
            SunRow(sunStyle: .sunset, diff: calculator.eveningTimeSinceSolistice, absolute: calculator.sunset)
        }
    }
}
