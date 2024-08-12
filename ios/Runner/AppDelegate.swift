import UIKit
import Flutter
import workmanager
import shared_preferences_foundation
import flutter_secure_storage
import path_provider_foundation
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        WorkmanagerPlugin.register(with: self.registrar(forPlugin: "be.tramckrijte.workmanager.WorkmanagerPlugin")!)

        WorkmanagerPlugin.registerTask(withIdentifier: "workmanager.background.task")
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
        
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
            SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")!)
            PathProviderPlugin.register(with: registry.registrar(forPlugin: "io.flutter.plugins.pathprovider.PathProviderPlugin")!)
            FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin")!)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

