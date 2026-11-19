import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity UI: Lock Screen banner + the four Dynamic Island presentations.
/// iOS renders these views from the data the app sends through ActivityKit.
@available(iOS 16.2, *)
struct OrderLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: OrderActivityAttributes.self) { context in
      // Lock Screen, Notification Center, and the banner on iPhones without a Dynamic Island
      OrderLockScreenView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(.orange)

    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded: shown when the user long-presses the island
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(context.attributes.storeName)
              .font(.caption).lineLimit(1)
          } icon: {
            Image(systemName: StepInfo.icon(for: context.state.step))
              .foregroundStyle(.orange)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          EtaText(eta: context.state.eta, delivered: context.state.step >= 3)
            .font(.headline)
            .foregroundStyle(.orange)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 70)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 8) {
            Text(context.state.statusText)
              .font(.subheadline.weight(.semibold))
            StepTracker(step: context.state.step)
            Text("Order #\(context.attributes.orderNumber) · \(context.attributes.itemsSummary)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      } compactLeading: {
        Image(systemName: StepInfo.icon(for: context.state.step))
          .foregroundStyle(.orange)
      } compactTrailing: {
        EtaText(eta: context.state.eta, delivered: context.state.step >= 3)
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.orange)
          .frame(maxWidth: 44)
      } minimal: {
        Image(systemName: StepInfo.icon(for: context.state.step))
          .foregroundStyle(.orange)
      }
      .widgetURL(URL(string: "liveactivitiesdemo://order/\(context.attributes.orderNumber)"))
      .keylineTint(.orange)
    }
  }
}

// MARK: - Lock Screen

@available(iOS 16.2, *)
struct OrderLockScreenView: View {
  let context: ActivityViewContext<OrderActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Image(systemName: StepInfo.icon(for: context.state.step))
          .foregroundStyle(.orange)
        Text(context.attributes.storeName)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
        Spacer()
        Text("#\(context.attributes.orderNumber)")
          .font(.caption)
          .foregroundStyle(.gray)
      }

      HStack(alignment: .firstTextBaseline) {
        Text(context.state.statusText)
          .font(.headline)
          .foregroundStyle(.white)
        Spacer()
        EtaText(eta: context.state.eta, delivered: context.state.step >= 3)
          .font(.title3.bold().monospacedDigit())
          .foregroundStyle(.orange)
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: 90)
      }

      StepTracker(step: context.state.step)

      Text(context.attributes.itemsSummary)
        .font(.caption)
        .foregroundStyle(.gray)
        .lineLimit(1)
    }
    .padding(16)
  }
}

// MARK: - Shared pieces

/// Live countdown rendered by iOS itself: no per-second updates needed from the app.
struct EtaText: View {
  let eta: Date
  let delivered: Bool

  var body: some View {
    if delivered {
      Text("Done")
    } else if eta > Date() {
      Text(timerInterval: Date()...eta, countsDown: true)
    } else {
      Text("Soon")
    }
  }
}

/// Four-step tracker: confirmed → preparing → on the way → delivered.
struct StepTracker: View {
  let step: Int

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<StepInfo.count, id: \.self) { index in
        Capsule()
          .fill(index <= step ? Color.orange : Color.gray.opacity(0.35))
          .frame(height: 5)
      }
    }
  }
}

enum StepInfo {
  static let count = 4

  static func icon(for step: Int) -> String {
    switch step {
    case 0: return "checkmark.circle.fill"
    case 1: return "flame.fill"
    case 2: return "bicycle"
    default: return "house.fill"
    }
  }
}
