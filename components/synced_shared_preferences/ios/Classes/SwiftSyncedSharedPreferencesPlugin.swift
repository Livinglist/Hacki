import Flutter
import UIKit
import Foundation

typealias APNSHandler = ()->Void

let keyKey = "key"
let valKey = "val"

final class SharedPrefsCore {
    fileprivate static let shared: SharedPrefsCore = SharedPrefsCore()

    fileprivate func setBool(key: String?, val: Bool?) -> Bool {
        guard let key = key,
              let val = val else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation;
        let allKeys = allVals.keys

        // Limit is 1024, reserve rest slots for fav and pins.
        if allKeys.count >= 1000 {
            for key in allKeys.filter({ $0.contains("hasRead") }) {
                keyStore.removeObject(forKey: key)
            }
        }

        keyStore.set(val, forKey: key)
        return true
    }

    fileprivate func getBool(key: String?) -> Bool {
        guard let key = key else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        let val = keyStore.bool(forKey: key)

        return val
    }

    fileprivate func setStringList(key: String?, val: [String]?) -> Bool {
        guard let key = key,
              let val = val else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        keyStore.set(val, forKey: key)

        return true
    }

    fileprivate func getStringList(key: String?) -> [Any] {
        guard let key = key else {
            return [Any]()
        }

        let keyStore = NSUbiquitousKeyValueStore()
        let list = keyStore.array(forKey: key) as [Any]? ?? [Any]()

        return list
    }

    fileprivate func clearAll() -> Bool{
        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation;
        let allKeys = allVals.keys

        for key in allKeys.filter({ $0.contains("hasRead") }) {
            keyStore.removeObject(forKey: key)
        }

        return true
    }
}

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
                let val = params[valKey] as? Bool
                let key = params[keyKey] as? String

                let res = SharedPrefsCore.shared.setBool(key: key, val: val)
                result(res)
            }

            return
        case "getBool":
            if let params  = call.arguments as? [String: Any] {
                let key = params[keyKey] as? String
                let res = SharedPrefsCore.shared.getBool(key: key)
                result(res)
            }

            return
        case "setStringList":
            if let params  = call.arguments as? [String: Any] {
                let val = params[valKey] as? [String]
                let key = params[keyKey] as? String

                let res = SharedPrefsCore.shared.setStringList(key: key, val: val)
                result(res)
            }

            return
        case "getStringList":
            if let params  = call.arguments as? [String: Any] {
                let key = params[keyKey] as? String
                let res = SharedPrefsCore.shared.getStringList(key: key)
                result(res)
            }

            return
        case "clearAll":
            if let params  = call.arguments as? [String: Any] {
                let res = SharedPrefsCore.shared.clearAll()
                result(res)
            }
            
            return
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
