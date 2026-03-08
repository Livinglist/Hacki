import UIKit
import Flutter
import workmanager_apple
import shared_preferences_foundation
import flutter_local_notifications
import flutter_secure_storage_darwin
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        WorkmanagerPlugin.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "be.tramckrijte.workmanager.WorkmanagerPlugin")!)

        WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "workmanager.background.task")
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }
        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
        
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
            if let registrarResult = registry.registrar(forPlugin: "FlutterSecureStorageDarwinPlugin") {
                FlutterSecureStorageDarwinPlugin.register(with: registrarResult)
            }
            if let registrarResult = registry.registrar(forPlugin: "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin") {
                SharedPreferencesPlugin.register(with: registrarResult)
            }
            if let registrarResult = registry.registrar(forPlugin: "com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin") {
                FlutterLocalNotificationsPlugin.register(with: registrarResult)
            }
        }
        
        let channel = FlutterMethodChannel(name: "image_saver",
                                           binaryMessenger: engineBridge.applicationRegistrar.messenger())

        channel.setMethodCallHandler { [weak self] call, result in
          if call.method == "saveImage" {
            self?.handleSaveImage(call: call, result: result)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
    }
    
    // MARK: - Save Image
    private func handleSaveImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard
        let args = call.arguments as? [String: Any],
        let bytes = args["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing or invalid bytes", details: nil))
        return
      }

      guard let image = UIImage(data: bytes.data) else {
        result(FlutterError(code: "INVALID_IMAGE", message: "Could not decode image", details: nil))
        return
      }

      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async {
          guard status == .authorized || status == .limited else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
            return
          }

          PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
          }) { success, error in
            DispatchQueue.main.async {
              if success {
                result(true)
              } else {
                result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
              }
            }
          }
        }
      }
    }
}

