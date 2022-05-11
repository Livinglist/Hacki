import Flutter
import UIKit

public class SwiftSyncedSharedPreferencesPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "synced_shared_preferences", binaryMessenger: registrar.messenger())
        let instance = SwiftSyncedSharedPreferencesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setBool":
            if let params  = call.arguments as? [String: Any] {
                let info: [String: Any] = ["result": result,
                                           "params": params]
                NotificationCenter.default.post(name: Notification.Name("setBool"), object: nil, userInfo: info)
            }
            
            return
        case "getBool":
            if let params  = call.arguments as? [String: Any] {
                let info: [String: Any] = ["result": result,
                                           "params": params]
                NotificationCenter.default.post(name: Notification.Name("getBool"), object: nil, userInfo: info)
            }
            
            return
        case "clearAll":
            if let params  = call.arguments as? [String: Any] {
                let info: [String: Any] = ["result": result,
                                           "params": params]
                NotificationCenter.default.post(name: Notification.Name("clearAll"), object: nil, userInfo: info)
            }
            
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
