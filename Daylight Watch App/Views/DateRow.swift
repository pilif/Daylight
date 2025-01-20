import SwiftUI

struct DateRow: View {
  var currentDate: Date
  var displayDate: Date
  @Binding var offset: Double
  @Binding var loading: Bool

  var body: some View {
    HStack(alignment: .top) {
      if loading {
        ProgressView()
          .frame(width: 10, height: 10, alignment: .topLeading)
          .padding(.trailing, 10)
      }

      Text("\(displayDate.formatted(date: .abbreviated, time: .omitted))")
        .padding(.bottom, 10)
      if !Calendar.current.isDate(currentDate, equalTo: displayDate, toGranularity: .day) {
        Button(
          action: {
            offset = 0
          },
          label: {
            Image(systemName: "x.circle.fill")
          }
        )
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  let current: Date = "2025-01-07 07:37:09"
  let display: Date = "2025-01-16 00:00:00"

  DateRow(
    currentDate: current, displayDate: display, offset: .constant(0.0), loading: .constant(false))
  DateRow(
    currentDate: current, displayDate: display, offset: .constant(0.0), loading: .constant(true))
}
