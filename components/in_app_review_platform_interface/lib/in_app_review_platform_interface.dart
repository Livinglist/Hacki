import 'package:in_app_review_platform_interface/method_channel_in_app_review.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of in_app_review must implement.
///
/// Platform implementations should extend this class rather than implement it
/// as `in_app_review` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [InAppReviewPlatform] methods.
abstract class InAppReviewPlatform extends PlatformInterface {
  InAppReviewPlatform() : super(token: _token);

  static InAppReviewPlatform _instance = MethodChannelInAppReview();

  static final Object _token = Object();

  static InAppReviewPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [InAppReviewPlatform] when they register themselves.
  static set instance(InAppReviewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if the device is able to show a review dialog.
  ///
  /// On Android the Google Play Store must be installed and the device must be
  /// running **Android 5 Lollipop(API 21)** or higher.
  ///
  /// iOS devices must be running **iOS version 10.3** or higher.
  ///
  /// MacOS devices must be running **MacOS version 10.14** or higher
  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  /// Attempts to show the review dialog. It's recommended to first check if
  /// this cannot be done via [isAvailable]. If it is not available then
  /// you can open the store listing via [openStoreListing].
  ///
  /// To improve the users experience, iOS and Android enforce limitations
  /// that might prevent this from working after a few tries. iOS & MacOS users
  /// can also disable this feature entirely in the App Store settings.
  ///
  /// More info and guidance:
  /// https://developer.android.com/guide/playcore/in-app-review#when-to-request
  /// https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/ratings-and-reviews/
  /// https://developer.apple.com/design/human-interface-guidelines/macos/system-capabilities/ratings-and-reviews/
  Future<void> requestReview() {
    throw UnimplementedError('requestReview() has not been implemented.');
  }

  /// Opens the Play Store on Android, the App Store with a review
  /// screen on iOS & MacOS and the Microsoft Store on Windows.
  ///
  /// [appStoreId] is required for iOS & MacOS.
  ///
  /// [microsoftStoreId] is required for Windows.
  Future<void> openStoreListing({
    /// Required for iOS & MacOS.
    String? appStoreId,

    /// Required for Windows.
    String? microsoftStoreId,
  }) {
    throw UnimplementedError('openStoreListing() has not been implemented.');
  }
}
