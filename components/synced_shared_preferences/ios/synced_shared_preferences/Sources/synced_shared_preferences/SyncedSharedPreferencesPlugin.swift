import Flutter
import Foundation
import UIKit

private let keyKey = "key"
private let valKey = "val"

private final class SharedPrefsCore {
    static let shared = SharedPrefsCore()

    func setBool(key: String?, val: Bool?) -> Bool {
        guard let key = key,
              let val = val else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation
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

    func getBool(key: String?) -> Bool {
        guard let key = key else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        return keyStore.bool(forKey: key)
    }

    func setStringList(key: String?, val: [String]?) -> Bool {
        guard let key = key,
              let val = val else {
            return false
        }

        let keyStore = NSUbiquitousKeyValueStore()
        keyStore.set(val, forKey: key)

        return true
    }

    func getStringList(key: String?) -> [Any] {
        guard let key = key else {
            return [Any]()
        }

        let keyStore = NSUbiquitousKeyValueStore()
        return keyStore.array(forKey: key) as [Any]? ?? [Any]()
    }

    func clearAll() -> Bool {
        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation
        let allKeys = allVals.keys

        for key in allKeys.filter({ $0.contains("hasRead") }) {
            keyStore.removeObject(forKey: key)
        }

        return true
    }

    func remove(key: String?) -> Bool {
        if let key = key {
            let keyStore = NSUbiquitousKeyValueStore()
            keyStore.removeObject(forKey: key)
        }

        return true
    }
}

public class SyncedSharedPreferencesPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "synced_shared_preferences", binaryMessenger: registrar.messenger())
        let instance = SyncedSharedPreferencesPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "remove":
            if let params = call.arguments as? [String: Any] {
                let key = params[keyKey] as? String
                result(SharedPrefsCore.shared.remove(key: key))
            }

        case "setBool":
            if let params = call.arguments as? [String: Any] {
                let val = params[valKey] as? Bool
                let key = params[keyKey] as? String
                result(SharedPrefsCore.shared.setBool(key: key, val: val))
            }

        case "getBool":
            if let params = call.arguments as? [String: Any] {
                let key = params[keyKey] as? String
                result(SharedPrefsCore.shared.getBool(key: key))
            }

        case "setStringList":
            if let params = call.arguments as? [String: Any] {
                let val = params[valKey] as? [String]
                let key = params[keyKey] as? String
                result(SharedPrefsCore.shared.setStringList(key: key, val: val))
            }

        case "getStringList":
            if let params = call.arguments as? [String: Any] {
                let key = params[keyKey] as? String
                result(SharedPrefsCore.shared.getStringList(key: key))
            }

        case "clearAll":
            result(SharedPrefsCore.shared.clearAll())

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
