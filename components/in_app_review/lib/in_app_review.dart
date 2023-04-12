import 'dart:async';

import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';

class InAppReview {
  InAppReview._();

  static final InAppReview instance = InAppReview._();

  /// Checks if the device is able to show a review dialog.
  ///
  /// On Android the Google Play Store must be installed and the device must be
  /// running **Android 5 Lollipop(API 21)** or higher.
  ///
  /// iOS devices must be running **iOS version 10.3** or higher.
  ///
  /// MacOS devices must be running **MacOS version 10.14** or higher
  Future<bool> isAvailable() => InAppReviewPlatform.instance.isAvailable();

  /// Attempts to show the review dialog. It's recommended to first check if
  /// the device supports this feature via [isAvailable].
  ///
  /// To improve the users experience, iOS and Android enforce limitations
  /// that might prevent this from working after a few tries. iOS & MacOS users
  /// can also disable this feature entirely in the App Store settings.
  ///
  /// More info and guidance:
  /// https://developer.android.com/guide/playcore/in-app-review#when-to-request
  /// https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/ratings-and-reviews/
  /// https://developer.apple.com/design/human-interface-guidelines/macos/system-capabilities/ratings-and-reviews/
  Future<void> requestReview() => InAppReviewPlatform.instance.requestReview();

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
  }) =>
      InAppReviewPlatform.instance.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: microsoftStoreId,
      );
}
