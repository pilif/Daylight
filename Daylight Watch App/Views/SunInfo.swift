import Foundation
import SwiftUI

struct SunInfo: View {
  let formattedDiff: String
  let absolute: Date
  let preview: Date?

  var body: some View {
    VStack(alignment: .trailing) {
      Text("\(formattedDiff)")
        .font(.title3)

      if let preview {
        SunPreview(absolute: absolute, preview: preview)
      } else {
        Text("\(formattedDate)")
          .font(.footnote)
      }
    }
  }

  private var formattedDate: String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: absolute)
  }

}
