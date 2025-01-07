import SwiftUI

struct ContentView: View {
    @StateObject var locationViewModel = Location()
    
    var body: some View {
        switch locationViewModel.authorizationStatus {
        case .notDetermined:
            AnyView(RequestLocationView())
                .environmentObject(locationViewModel)
        case .restricted:
            ErrorView(errorText: "Location use is restricted.")
        case .denied:
            ErrorView(errorText: "The app does not have location permissions. Please enable them in settings.")
        case .authorizedAlways, .authorizedWhenInUse:
            SunView()
                .environmentObject(locationViewModel)
        default:
            Text("Unexpected status")
        }
    }
}

#Preview {
    ContentView()
}
