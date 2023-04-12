# in_app_review

![tests](https://github.com/britannio/in_app_review/workflows/tests/badge.svg?branch=master)
[![pub package](https://img.shields.io/pub/v/in_app_review.svg)](https://pub.dartlang.org/packages/in_app_review) ![In-App Review Android Demo](https://github.com/britannio/in_app_review/blob/master/in_app_review/screenshots/android.jpg)
![In-App Review iOS Demo](https://github.com/britannio/in_app_review/blob/master/in_app_review/screenshots/ios.png)

# Description

A Flutter plugin that lets you show a review pop up where users can leave a review for your app without needing to close your app. Alternatively, you can open your store listing via a deep link.

It uses the [In-App Review](https://developer.android.com/guide/playcore/in-app-review) API on Android and the [SKStoreReviewController](https://developer.apple.com/documentation/storekit/skstorereviewcontroller) on iOS/MacOS.

# Usage

## `requestReview()`

The following code triggers the In-App Review prompt. This should **not** be used frequently as the underlying API's enforce strict quotas on this feature to provide a great user experience.

```dart
import 'package:in_app_review/app_review_service.dart';

final InAppReview inAppReview = InAppReview.instance;

if (await inAppReview.isAvailable()) {
    inAppReview.requestReview();
}
```

### Do

- Use this after a user has experienced your app for long enough to provide useful feedback, e.g., after the completion of a game level or after a few days.
- Use this sparingly otherwise no pop up will appear.

### Avoid

- Triggering this via a button in your app as it will only work when the quota enforced by the underlying API has not been exceeded. ([Android](https://developer.android.com/guide/playcore/in-app-review#quotas))
- Interrupting the user if they are mid way through a task.

**Testing `requestReview()` on Android isn't as simple as running your app via the emulator or a physical device. See [Testing](#testing) for more info.**

---

## `openStoreListing()`

The following code opens the Google Play Store on Android, the App Store with a review screen on iOS & MacOS and the Microsoft Store on Windows. Use this if you want to permanently provide a button or other call-to-action to let users leave a review as it isn't restricted by a quota.

```dart
import 'package:in_app_review/app_review_service.dart';

final InAppReview inAppReview = InAppReview.instance;

inAppReview.openStoreListing(appStoreId: '...', microsoftStoreId: '...');
```

`appStoreId` is only required on iOS and MacOS and can be found in App Store Connect under General > App Information > Apple ID.

`microsoftStoreId` is only required on Windows.

# Guidelines
<https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/ratings-and-reviews/>

<https://developer.android.com/guide/playcore/in-app-review#when-to-request>
<https://developer.android.com/guide/playcore/in-app-review#design-guidelines>

Since there is a quota on how many times the pop up can be shown, you should **not** trigger `requestReview()` via a button or other *call-to-action* option. Instead, you can reliably redirect users to your store listing via `openStoreListing()`.

# Testing

## Android

You must upload your app to the Play Store to test `requestReview()`. An easy way to do this is to build an apk/app bundle and upload it via [internal app sharing](https://play.google.com/apps/publish/internalappsharing/).

Real reviews cannot be created while testing `requestReview()` and the **submit** button is disabled to emphasize this.

More details at <https://developer.android.com/guide/playcore/in-app-review/test>

## iOS

`requestReview()` can be tested via the iOS simulator or on a physical device.
Note that `requestReview()` has no effect when testing via TestFlight [as documented](https://developer.apple.com/documentation/storekit/skstorereviewcontroller/2851536-requestreview#discussion).

Real reviews cannot be created while testing `requestReview()` and the **submit** button is disabled to emphasize this.

`openStoreListing()` can only be tested with a physical device as the iOS simulator does not have the App Store installed.

## MacOS

This plugin can be tested by running your MacOS application locally.

# Cross Platform Compatibility

| Function             | Android | iOS | MacOS | Windows(UWP) |
|----------------------|---------|-----|-------|--------------|
| `isAvailable()`      | ✅       | ✅   | ✅     | ❌            |
| `requestReview()`    | ✅       | ✅   | ✅     | ❌            |
| `openStoreListing()` | ✅       | ✅   | ✅     | ✅            |

Upvote <https://github.com/flutter/flutter/issues/14967> if you're interested in Windows support!

# Requirements

## Android

Requires Android 5 Lollipop(API 21) or higher and the Google Play Store must be installed.

## iOS

Requires iOS version 10.3

## MacOS

Requires MacOS version 10.14

Issues & pull requests are more than welcome!
