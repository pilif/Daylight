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
    absolute: "2025-01-09 06:35:22+01",
    preview: "2025-03-02 06:35:22+01"
  )

  SunPreview(
    absolute: "2025-01-09 06:35:22+01",
    preview: "2025-01-11 06:35:22+01"
  )
}
