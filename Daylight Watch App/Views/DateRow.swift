import SwiftUI

struct DateRow: View {
  var currentDate: Date
  var displayDate: Date
  @Binding var offset: Double

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
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
  let current = Date(timeIntervalSince1970: 1_736_231_829)
  let display = Date(timeIntervalSince1970: 1_736_985_600)

  DateRow(currentDate: current, displayDate: display, offset: .constant(0.0))
}
