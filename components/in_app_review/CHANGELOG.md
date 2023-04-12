# [2.0.6]
- Update Android Play Core dependency to Play Review 2.0.1.

# [2.0.5]

- Migrate Android Play Core dependency to Play Review 2.0.0.
- Recreate the example app.
- Update in_app_review_platform_interface to 2.0.4

# [2.0.4]

- Migrate maven repository from jcenter to mavenCentral
- `isAvailable()` now returns `false` on web.

# [2.0.3]

- Fix iOS no-scene exception. ([#41](https://github.com/britannio/in_app_review/issues/41))
# [2.0.2]

- Replace iOS Swift code with Objective-C to add compatibility with Objective-C Flutter apps.

# [2.0.1]

- Fix rare null pointer exception on Android
- Fix MissingPluginException on MacOS
- Bump the minimum Dart SDK version from `2.12.0-0` to `2.12.0`.
- Bump the minimum Flutter version to `2.0.0`.
- Update in_app_review_platform_interface to 2.0.2

# [2.0.0]

- Migrate to null safety.

# [1.0.4]

- Update in_app_review_platform_interface to 1.0.5
- Remove dependency on `package_info`.
- Handle `openStoreListing()` with native code for Android, iOS and MacOS.

# [1.0.3]

- Update in_app_review_platform_interface to 1.0.4
- Update android compileSdkVersion to 29.
- Lower dependency version constraints.

# [1.0.2]

- Update in_app_review_platform_interface to 1.0.3
- Open the App Store directly instead of via the Safari View Controller.
- Add automated tests.
- Improve docs.

# [1.0.1+1]

- Update in_app_review_platform_interface to 1.0.2

# [1.0.0]

- Migrate to use `in_app_review_platform_interface`.
- Add Windows support for `openStoreListing`.

# [0.2.1+1]

- Improve iOS testing docs.

# [0.2.1]

- Update dependencies.
- Android Play Core Library V1.8.2 release notes:
    - Fixed UI flickering in the In-App Review API

# [0.2.0+4]

- Remove deprecated API warning.
- Update dependencies.

# [0.2.0+3]

- Instructions in the README have been improved along with the example.

# [0.2.0+2]

- Update changelog format

# [0.2.0+1]

- Update MacOS testing instructions

# [0.2.0] Breaking Change

- Add MacOS support
- Rename `openStoreListing(iOSAppStoreId: '')` to `openStoreListing(appStoreId: '')` 

# [0.1.0]

- Improve docs
- Set Android minSdkVersion to 16
- Refactor Android Plugin

# [0.0.1]

Initial release
