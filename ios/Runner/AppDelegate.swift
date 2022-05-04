import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
