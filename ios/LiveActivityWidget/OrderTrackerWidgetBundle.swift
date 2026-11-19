import SwiftUI
import WidgetKit

// The widget extension's deployment target is iOS 16.2,
// so the Live Activity can be listed directly.
@main
struct OrderTrackerWidgetBundle: WidgetBundle {
  var body: some Widget {
    OrderLiveActivity()
  }
}
