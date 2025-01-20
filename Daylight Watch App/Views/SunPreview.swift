import SwiftUI

struct SunPreview: View {
  var absolute: Date
  var preview: Date
  @State var formatAsDate = false

  var body: some View {
    HStack {
      Image(systemName: "sparkles")
        .symbolRenderingMode(.multicolor)
      if formatAsDate {
        Text(formatAsDate(date: preview))
          .font(.footnote)
      } else {
        Text("\(formatAsDays(date: preview))")
          .font(.footnote)
      }
    }.onTapGesture {
      formatAsDate.toggle()
    }
  }

  private func formatAsDate(date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM dd, HH:mm"

    return f.string(from: date)
  }

  private func formatAsDays(date: Date) -> String {
    let daysLeft = abs(
      Calendar.current.dateComponents([.day], from: date, to: self.absolute).day ?? 0)

    let f = DateFormatter()
    f.dateFormat = "HH:mm"

    return "in \(daysLeft)d, " + f.string(from: date)
  }
}

#Preview {
  SunPreview(
    absolute: "2025-01-09 06:35:22+01",
    preview: "2025-03-02 06:35:22+01"
  )

  SunPreview(
    absolute: "2025-01-09 06:35:22+01",
    preview: "2025-01-11 06:35:22+01",
    formatAsDate: true
  )
}
