import SwiftUI

struct RequestLocationView: View {
    @EnvironmentObject var locationViewModel: Location
    
    var body: some View {
        VStack {
            Button(action: {
                locationViewModel.requestPermission()
            }, label: {
                Label("Allow location access", systemImage: "location")
            })
            .padding(10)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("We need your permission to know where you are in order to show you the sunrise and sunset times")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}

#Preview {
    RequestLocationView()
}
