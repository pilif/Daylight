import Foundation
import SwiftUI

struct SunTimeline: View {
  @EnvironmentObject var locationViewModel: Location

  var body: some View {
    TimelineView(.periodic(from: Date(), by: 1)) { context in
      SunView(currentDate: context.date)
    }
  }
}
