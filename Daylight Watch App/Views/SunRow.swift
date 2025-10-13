import SwiftUI

struct SunRow: View {
  let systemName: String
  let diff: TimeInterval
  let diffPreview: Date?
  let absolute: Date
  let preview: Date?
  let countdown: TwilightCountdown

  var body: some View {
    HStack {
      Image(systemName: self.systemName)
        .symbolRenderingMode(.multicolor)
        .resizable()
        .scaledToFit()
        .frame(width: 64.0)
      Spacer()
      switch countdown {
      case .none:
        SunInfo(formattedDiff: formattedDiff, absolute: self.absolute, preview: self.preview)
      case .civil(let ti):
        TwilightCountdownView(
          label: "Civil", at: ti, absolute: self.absolute, preview: self.preview)
      case .nautical(let ti):
        TwilightCountdownView(
          label: "Nautical", at: ti, absolute: self.absolute, preview: self.preview)
      }
    }
  }

  private var formattedDiff: String {
    if diff < 0 {
      if let diffPreview = diffPreview {
        let f = DateFormatter()
        f.dateFormat = "MMM, dd"
        if let s = f.string(for: diffPreview) {
          return s
        }
      }
    }

    let str =
      (abs(diff) > 60 * 60)
      ? Duration(timeval(tv_sec: Int(diff), tv_usec: 0)).formatted(.time(pattern: .hourMinute))
        + " h"
      : Duration(timeval(tv_sec: Int(diff), tv_usec: 0)).formatted(.time(pattern: .minuteSecond))
        + " min"
    let prefix = diff >= 0 ? "+" : ""

    return "\(prefix)\(str)"
  }

  init(
    sunStyle: SunStyle, diff: TimeInterval, diffPreview: Date?, absolute: Date, preview: Date?,
    countdown: TwilightCountdown
  ) {
    systemName =
      switch sunStyle {
      case .sunrise:
        "sunrise.fill"
      case .sunset:
        "sunset.fill"
      }
    self.diff = diff
    self.diffPreview = diffPreview
    self.absolute = absolute
    self.preview = preview
    self.countdown = countdown
  }
}

#Preview {
  SunRow(
    sunStyle: .sunrise,
    diff: -101.0,
    diffPreview: "2026-03-12 07:37:09",
    absolute: "2025-10-13 07:37:09",
    preview: nil,
    countdown: .none
  )
  SunRow(
    sunStyle: .sunrise,
    diff: 101.0,
    diffPreview: nil,
    absolute: "2025-01-07 07:37:09",
    preview: "2025-01-11 06:35:22",
    countdown: .none
  )
  SunRow(
    sunStyle: .sunrise,
    diff: 101.0,
    diffPreview: nil,
    absolute: "2025-01-07 07:37:09",
    preview: "2025-01-16 01:00:00+01",
    countdown: .nautical(in: 60)
  )
}
