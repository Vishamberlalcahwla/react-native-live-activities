import ActivityKit
import Foundation

/// Data model for the order-tracking Live Activity.
///
/// Single source of truth, shipped as the `OrderActivityShared` pod and
/// linked into BOTH the app (via LiveActivityModule) and the widget extension.
/// No React dependency, so it is safe to link into an app extension.
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
