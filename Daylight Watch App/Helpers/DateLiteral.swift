import Foundation

extension Date: @retroactive ExpressibleByStringLiteral {
  public init(stringLiteral value: StaticString) {
    let formatterWithTime = ISO8601DateFormatter()
    formatterWithTime.formatOptions = [
      .withFullDate,
      .withTime,
      .withSpaceBetweenDateAndTime,
      .withDashSeparatorInDate,
      .withColonSeparatorInTime,
    ]
    formatterWithTime.timeZone = TimeZone(identifier: "Europe/Zurich")

    let formatterDateOnly = ISO8601DateFormatter()
    formatterDateOnly.formatOptions = [
      .withFullDate,
      .withDashSeparatorInDate,
    ]
    self =
      formatterWithTime.date(from: "\(value)")
      ?? formatterDateOnly.date(from: "\(value)")
      ?? Date(timeIntervalSince1970: 1)
  }
}
