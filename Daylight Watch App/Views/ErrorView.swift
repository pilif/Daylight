import SwiftUI

struct ErrorView: View {
  var errorText: String

  var body: some View {
    VStack {
      Image(systemName: "xmark.octagon")
        .resizable()
        .frame(width: 64, height: 64, alignment: .center)
      Text(errorText)
    }
    .padding()
  }
}

#Preview {
  ErrorView(errorText: "Gnegg")
}
