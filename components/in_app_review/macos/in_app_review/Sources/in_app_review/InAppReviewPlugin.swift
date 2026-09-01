import Cocoa
import FlutterMacOS
import StoreKit

public class InAppReviewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dev.britannio.in_app_review", binaryMessenger: registrar.messenger)
    let instance = InAppReviewPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestReview":
      //App Store Review
      if #available(OSX 10.14, *) {
        SKStoreReviewController.requestReview()
        result(nil)
      } else {
        result(FlutterError(code: "unavailable", message: "In-App Review unavailable", details: nil))
      }
    case "isAvailable":
      if #available(OSX 10.14, *) {
        result(true)
      } else {
        result(false)
      }
    case "openStoreListing":
        let storeId : String = call.arguments as! String;
        
        guard let writeReviewURL = URL(string: "macappstore://apps.apple.com/app/id" + storeId + "?action=write-review")
        else {
            result(FlutterError(code: "url_construct_fail", message: "Failed to construct url", details: nil))
            return
        }
        NSWorkspace.shared.open(writeReviewURL)
        result(nil);
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
