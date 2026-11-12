import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UserDefaults.standard.set(true, forKey: "FIRAnalyticsDebugEnabled")
    // With UIScene, Flutter only turns the GPU back on for
    // UIApplication.willEnterForegroundNotification, and iOS does not always
    // deliver that. The last frame then stays up and ignores touches until a
    // force-quit. Post it ourselves when the scene actually returns.
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(reenableFlutterRendering),
      name: UIScene.willEnterForegroundNotification,
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(reenableFlutterRendering),
      name: UIScene.didActivateNotification,
      object: nil
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func reenableFlutterRendering() {
    NotificationCenter.default.post(
      name: UIApplication.willEnterForegroundNotification,
      object: UIApplication.shared
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
