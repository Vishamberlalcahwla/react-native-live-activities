import ActivityKit
import Foundation
import OrderActivityShared
import React

/// React Native native module that starts, updates and ends
/// order-tracking Live Activities through ActivityKit.
@objc(LiveActivityModule)
class LiveActivityModule: NSObject {

  @objc static func requiresMainQueueSetup() -> Bool { false }

  // MARK: - Availability

  @objc(isSupported:rejecter:)
  func isSupported(_ resolve: @escaping RCTPromiseResolveBlock,
                   rejecter reject: @escaping RCTPromiseRejectBlock) {
    if #available(iOS 16.2, *) {
      resolve(ActivityAuthorizationInfo().areActivitiesEnabled)
    } else {
      resolve(false)
    }
  }

  // MARK: - Start

  @objc(start:state:resolver:rejecter:)
  func start(_ order: NSDictionary,
             state: NSDictionary,
             resolver resolve: @escaping RCTPromiseResolveBlock,
             rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else {
      reject("UNSUPPORTED", "Live Activities require iOS 16.2 or later", nil)
      return
    }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      reject("DISABLED", "Live Activities are turned off for this app in Settings", nil)
      return
    }

    let attributes = OrderActivityAttributes(
      orderNumber: order["orderNumber"] as? String ?? "",
      storeName: order["storeName"] as? String ?? "",
      itemsSummary: order["itemsSummary"] as? String ?? ""
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: ActivityContent(state: Self.contentState(from: state), staleDate: nil),
        pushType: nil // use .token to receive updates from your server via APNs
      )
      resolve(activity.id)
    } catch {
      reject("START_FAILED", error.localizedDescription, error)
    }
  }

  // MARK: - Update

  @objc(update:state:resolver:rejecter:)
  func update(_ activityId: String,
              state: NSDictionary,
              resolver resolve: @escaping RCTPromiseResolveBlock,
              rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { resolve(nil); return }
    guard let activity = Self.findActivity(activityId) else {
      reject("NOT_FOUND", "No Live Activity with id \(activityId)", nil)
      return
    }
    let content = ActivityContent(state: Self.contentState(from: state), staleDate: nil)
    Task {
      await activity.update(content)
      resolve(nil)
    }
  }

  // MARK: - End

  @objc(end:finalState:resolver:rejecter:)
  func end(_ activityId: String,
           finalState: NSDictionary?,
           resolver resolve: @escaping RCTPromiseResolveBlock,
           rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { resolve(nil); return }
    guard let activity = Self.findActivity(activityId) else { resolve(nil); return }

    // With a final state, keep it on the Lock Screen briefly ("Delivered");
    // without one, remove it immediately.
    let content = finalState.map {
      ActivityContent(state: Self.contentState(from: $0), staleDate: nil)
    }
    let policy: ActivityUIDismissalPolicy =
      content == nil ? .immediate : .after(Date().addingTimeInterval(15 * 60))

    Task {
      await activity.end(content, dismissalPolicy: policy)
      resolve(nil)
    }
  }

  @objc(endAll:rejecter:)
  func endAll(_ resolve: @escaping RCTPromiseResolveBlock,
              rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { resolve(nil); return }
    Task {
      for activity in Activity<OrderActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      resolve(nil)
    }
  }

  // MARK: - Helpers

  @available(iOS 16.2, *)
  private static func findActivity(_ id: String) -> Activity<OrderActivityAttributes>? {
    Activity<OrderActivityAttributes>.activities.first { $0.id == id }
  }

  @available(iOS 16.2, *)
  private static func contentState(from s: NSDictionary) -> OrderActivityAttributes.ContentState {
    let etaMs = (s["etaTimestamp"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970 * 1000
    return .init(
      step: (s["step"] as? NSNumber)?.intValue ?? 0,
      statusText: s["statusText"] as? String ?? "",
      eta: Date(timeIntervalSince1970: etaMs / 1000)
    )
  }
}
