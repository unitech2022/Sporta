import EventKit
import EventKitUI
import Flutter
import UIKit

/// «أضف إلى التقويم» على iOS: يعرض شاشة «موعد جديد» الأصلية معبّأة.
///
/// بديل عن عرض add_2_calendar على iOS: تلك تعرض الشاشة على
/// `UIApplication.keyWindow` وهو nil في تطبيقات المشاهد (UIScene) كهذا
/// التطبيق، فلا يظهر شيء. هنا نأخذ النافذة الفعّالة من المشهد المتصل.
/// على iOS 17+ تعمل الشاشة خارج العملية فلا تحتاج إذن التقويم.
final class CalendarBridge: NSObject, EKEventEditViewDelegate {
  static let shared = CalendarBridge()

  private let store = EKEventStore()
  private var pending: FlutterResult?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "sporta/calendar", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "addEvent", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.addEvent(args, result: result)
    }
  }

  private func addEvent(_ args: [String: Any], result: @escaping FlutterResult) {
    let show = { DispatchQueue.main.async { self.present(args, result: result) } }
    if #available(iOS 17, *) {
      show()
      return
    }
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
      show()
    case .notDetermined:
      store.requestAccess(to: .event) { granted, _ in
        if granted { show() } else { DispatchQueue.main.async { result(Self.denied) } }
      }
    default:
      result(Self.denied)
    }
  }

  private static let denied = FlutterError(
    code: "DENIED", message: "Calendar access denied", details: nil)

  private func present(_ args: [String: Any], result: @escaping FlutterResult) {
    guard pending == nil, let top = Self.topViewController(),
          let start = (args["start"] as? NSNumber)?.doubleValue,
          let end = (args["end"] as? NSNumber)?.doubleValue else {
      result(FlutterError(code: "UNAVAILABLE", message: "Cannot present", details: nil))
      return
    }
    let event = EKEvent(eventStore: store)
    event.title = args["title"] as? String
    event.notes = args["description"] as? String
    event.location = args["location"] as? String
    event.startDate = Date(timeIntervalSince1970: start / 1000)
    event.endDate = Date(timeIntervalSince1970: end / 1000)
    if let minutes = (args["alarmMinutes"] as? NSNumber)?.doubleValue, minutes > 0 {
      event.addAlarm(EKAlarm(relativeOffset: -minutes * 60))
    }

    let editor = EKEventEditViewController()
    editor.eventStore = store
    editor.event = event
    editor.editViewDelegate = self
    pending = result
    top.present(editor, animated: true)
  }

  func eventEditViewController(
    _ controller: EKEventEditViewController,
    didCompleteWith action: EKEventEditViewAction
  ) {
    controller.dismiss(animated: true)
    pending?(action == .saved)
    pending = nil
  }

  /// أعلى شاشة معروضة في النافذة الفعّالة للمشهد المتصل.
  private static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    let window = windows.first { $0.isKeyWindow } ?? windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
