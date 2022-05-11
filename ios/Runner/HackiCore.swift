//
//  HackiCore.swift
//  Runner
//
//  Created by Jiaqi Feng on 5/10/22.
//

import Foundation
import Flutter

extension Notification.Name {
    static let setBool = Notification.Name("setBool")
    static let getBool = Notification.Name("getBool")
    static let clearAll = Notification.Name("clearAll")
}

typealias APNSHandler = ()->Void

final class HackiCore: NSObject {
    private static let keyKey = "key"
    private static let valKey = "val"
    
    private static let shared: HackiCore = HackiCore()
    private let notificationCenter = NotificationCenter.default
    
    // Called at app launch
    class func start() {
        shared.registerNotifications()
    }
    
    private class func setupFlutterEvent(channelName: String, handler: NSObjectProtocol & FlutterStreamHandler) {
        guard let rootVC = UIApplication.shared.delegate?.window.unsafelyUnwrapped?.rootViewController as? FlutterViewController else { return }
        let eventChannel = FlutterEventChannel(name: channelName, binaryMessenger: rootVC.binaryMessenger)
        eventChannel.setStreamHandler(handler)
    }
    
    private func registerNotifications() {
        // SyncedSharedPreferences
        notificationCenter.addObserver(self, selector: #selector(setBool(_:)), name: .setBool, object: nil)
        notificationCenter.addObserver(self, selector: #selector(getBool(_:)), name: .getBool, object: nil)
        notificationCenter.addObserver(self, selector: #selector(clearAll(_:)), name: .clearAll, object: nil)
    }
    
    @objc private func setBool(_ notification: Notification) {
        guard let resultCompletionBlock: FlutterResult = notification.userInfo?["result"] as? FlutterResult else { fatalError(" failed to obtain result block") }
        guard
            let params = notification.userInfo?["params"] as? [String: Any],
            let key = params[HackiCore.keyKey] as? String,
            let val = params[HackiCore.valKey] as? Bool else {
            resultCompletionBlock(false)
            return
        }
        
        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation;
        let allKeys = allVals.keys
        
        if allKeys.count >= 1024 {
            for key in allKeys {
                keyStore.removeObject(forKey: key)
            }
        }
        
        keyStore.set(val, forKey: key)
        
        resultCompletionBlock(true)
    }
    
    @objc private func getBool(_ notification: Notification) {
        guard let resultCompletionBlock: FlutterResult = notification.userInfo?["result"] as? FlutterResult else { fatalError(" failed to obtain result block") }
        guard
            let params = notification.userInfo?["params"] as? [String: Any],
            let key = params[HackiCore.keyKey] as? String else {
            resultCompletionBlock(false)
            return
        }
        
        let keyStore = NSUbiquitousKeyValueStore()
        let val = keyStore.bool(forKey: key)
        
        resultCompletionBlock(val)
    }
    
    @objc private func clearAll(_ notification: Notification) {
        guard let resultCompletionBlock: FlutterResult = notification.userInfo?["result"] as? FlutterResult else { fatalError(" failed to obtain result block") }
        
        let keyStore = NSUbiquitousKeyValueStore()
        let allVals = keyStore.dictionaryRepresentation;
        let allKeys = allVals.keys
        
        for key in allKeys {
            keyStore.removeObject(forKey: key)
        }
        
        resultCompletionBlock(true)
    }
}

