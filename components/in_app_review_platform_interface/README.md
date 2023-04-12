# in_app_review_platform_interface

A common platform interface for the [`in_app_review`][1] plugin.

This interface allows platform-specific implementations of the `in_app_review`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `in_app_review`, extend
[`InAppReviewPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`InAppReviewPlatform` by calling
`InAppReviewPlatform.instance = MyInAppReview()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: ../in_app_review
[2]: lib/in_app_review_platform_interface.dart