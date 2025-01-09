import SwiftUI

struct SunRow: View {
  let systemName: String
  let diff: TimeInterval
  let absolute: Date
  let preview: Date?

  var body: some View {
    HStack {
      Image(systemName: self.systemName)
        .symbolRenderingMode(.multicolor)
        .resizable()
        .scaledToFit()
        .frame(width: 64.0)
      Spacer()
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
  }

  private var formattedDate: String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f.string(from: absolute)
  }

  private var formattedDiff: String {
    let str =
      (abs(diff) > 60 * 60)
      ? Duration(timeval(tv_sec: Int(diff), tv_usec: 0)).formatted(.time(pattern: .hourMinute))
        + " h"
      : Duration(timeval(tv_sec: Int(diff), tv_usec: 0)).formatted(.time(pattern: .minuteSecond))
        + " min"
    let prefix = diff >= 0 ? "+" : ""

    return "\(prefix)\(str)"
  }

  init(sunStyle: SunStyle, diff: TimeInterval, absolute: Date, preview: Date?) {
    systemName =
      switch sunStyle {
      case .sunrise:
        "sunrise.fill"
      case .sunset:
        "sunset.fill"
      }
    self.diff = diff
    self.absolute = absolute
    self.preview = preview
  }
}

#Preview {
  SunRow(
    sunStyle: .sunrise,
    diff: 101.0,
    absolute: Date(timeIntervalSince1970: 1_736_231_829),
    preview: nil
  )
  SunRow(
    sunStyle: .sunrise,
    diff: 101.0,
    absolute: Date(timeIntervalSince1970: 1_736_231_829),
    preview: Date(timeIntervalSince1970: 1_736_573_722)
  )
  SunRow(
    sunStyle: .sunrise,
    diff: 101.0,
    absolute: Date(timeIntervalSince1970: 1_736_231_829),
    preview: Date(timeIntervalSince1970: 1_736_985_600)
  )
}
