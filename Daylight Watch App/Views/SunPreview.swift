import SwiftUI

struct SunPreview: View {
  var absolute: Date
  var preview: Date

  var body: some View {
    HStack {
      Image(systemName: "sparkles")
        .symbolRenderingMode(.multicolor)
      Text("\(formatAsPreview(date: preview))")
        .font(.footnote)

    }
  }

  private func formatAsPreview(date: Date) -> String {
    let f = RelativeDateTimeFormatter()
    f.dateTimeStyle = .named

    if abs(Calendar.current.dateComponents([.day], from: date, to: self.absolute).day ?? 0) > 7 {
      let f = DateFormatter()
      f.dateFormat = "MMM dd (HH:mm)"
      return f.string(from: date)
    } else {
      return f.localizedString(for: date, relativeTo: self.absolute)
    }
  }
}

#Preview {
  SunPreview(
    absolute: Date(timeIntervalSince1970: 1_736_400_922),
    preview: Date(timeIntervalSince1970: 1_740_893_722)
  )

  SunPreview(
    absolute: Date(timeIntervalSince1970: 1_736_400_922),
    preview: Date(timeIntervalSince1970: 1_736_573_722)
  )
}
