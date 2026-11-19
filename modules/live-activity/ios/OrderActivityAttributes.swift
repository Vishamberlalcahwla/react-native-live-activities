import ActivityKit
import Foundation

/// Data model for the order-tracking Live Activity.
///
/// IMPORTANT: this file exists twice, once for the app
/// (`modules/live-activity/ios/`) and once for the widget extension
/// (`ios/LiveActivityWidget/`).
/// ActivityKit matches the app and the widget extension by type name,
/// so keep both copies in sync (same name, same fields, same types).
@available(iOS 16.1, *)
public struct OrderActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// 0 = confirmed, 1 = preparing, 2 = on the way, 3 = delivered
    public var step: Int
    /// Short human-readable status, e.g. "Your order is on the way"
    public var statusText: String
    /// Estimated arrival time. The widget renders a live countdown to it,
    /// so the app does not need to send an update every second.
    public var eta: Date

    public init(step: Int, statusText: String, eta: Date) {
      self.step = step
      self.statusText = statusText
      self.eta = eta
    }
  }

  // Static for the lifetime of the activity
  public var orderNumber: String
  public var storeName: String
  public var itemsSummary: String

  public init(orderNumber: String, storeName: String, itemsSummary: String) {
    self.orderNumber = orderNumber
    self.storeName = storeName
    self.itemsSummary = itemsSummary
  }
}
