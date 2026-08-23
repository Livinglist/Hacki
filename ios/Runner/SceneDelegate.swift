import Flutter
import UIKit

enum PendingDeepLink {
    static var urlString: String?

    static func capture(from connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            urlString = url.absoluteString
            return
        }
        if let webpageURL = connectionOptions.userActivities.compactMap({ $0.webpageURL }).first {
            urlString = webpageURL.absoluteString
        }
    }

    static func consume() -> String? {
        let value = urlString
        urlString = nil
        return value
    }
}

class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        PendingDeepLink.capture(from: connectionOptions)
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
