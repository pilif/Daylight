import Foundation

enum SunTransitionFormatting {
  static func difference(_ difference: TimeInterval?, absolute: Date, previewDate: Date?) -> String
  {
    if let previewDate {
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM, dd"
      return formatter.string(from: previewDate)
    }
    guard let difference else {
      return clockTime(absolute)
    }

    let absoluteDifference = abs(difference)
    let value: String
    if absoluteDifference > 60 * 60 {
      value =
        Duration(timeval(tv_sec: Int(difference), tv_usec: 0))
        .formatted(.time(pattern: .hourMinute)) + " h"
    } else if absoluteDifference >= 60 {
      value =
        Duration(timeval(tv_sec: Int(difference), tv_usec: 0))
        .formatted(.time(pattern: .minuteSecond)) + " min"
    } else {
      value = "\(Int(absoluteDifference.rounded())) s"
    }
    return difference >= 0 ? "+\(value)" : value
  }

  static func clockTime(_ date: Date) -> String {
    date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
  }

  static func preview(absolute: Date, preview: Date, calendar: Calendar = .current) -> String {
    let days = calendar.dateComponents([.day], from: absolute, to: preview).day ?? 0
    return "in \(days)d, \(clockTime(preview))"
  }
}
