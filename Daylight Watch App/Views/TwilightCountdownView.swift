import Foundation
import SwiftUI

struct TwilightCountdownView: View {
  let label: String
  let at: TimeInterval
  let absolute: Date
  let preview: Date?

  var body: some View {
    VStack(alignment: .trailing) {

      HStack {
        Text("\(label) in \(formattedInterval(interval: at))")
          .font(.caption)
      }
      HStack {
        Spacer()
        if let preview {
          SunPreview(absolute: absolute, preview: preview)
        } else {
          Text(formattedDate).font(.footnote)
        }
      }
    }
  }

  private func formattedInterval(interval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: interval) ?? ""
  }

  private var formattedDate: String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: absolute)
  }
}

#Preview {
  TwilightCountdownView(
    label: "Civil Dawn",
    at: 2 * 60 * 60 + 61,
    absolute: "2025-01-07 07:37:09",
    preview: nil
  )

  TwilightCountdownView(
    label: "Civil Dawn",
    at: 70,
    absolute: "2025-01-07 07:37:09",
    preview: "2025-01-11 06:35:22"
  )

}
