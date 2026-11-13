import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/web_analyzer.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Fixed relative dates keep these fixtures independent of the wall clock.
class ScreenStory extends Story {
  const ScreenStory({
    super.id = 100,
    super.title = 'Building a calmer internet',
  }) : super(
         descendants: 42,
         score: 128,
         time: 1704067200,
         by: 'alex',
         type: 'story',
         url: 'https://example.com/articles/a-calmer-internet',
         text: '',
         kids: const <int>[101],
         parts: const <int>[],
         hidden: false,
       );

  @override
  String get timeAgo => '2 hours ago';

  @override
  String get shortTimeAgo => '2h';
}

class ScreenComment extends Comment {
  ScreenComment()
    : super(
        id: 101,
        time: 1704067200,
        parent: 100,
        score: 7,
        by: 'robin',
        text:
            'Thoughtful defaults make a big difference. '
            '<p>Here is a <i>small</i> experiment worth sharing.',
        kids: <int>[],
        dead: false,
        deleted: false,
        hidden: false,
        level: 0,
        isFromCache: false,
      );

  @override
  String get timeAgo => '1 hour ago';

  @override
  String get shortTimeAgo => '1h';
}

void seedScreenPreview() {
  const ScreenStory story = ScreenStory();
  WebAnalyzer.cacheMap[WebAnalyzer.getKey(story)] = WebInfo(
    title: story.title,
    description:
        'Small communities, thoughtful conversations, and tools that give '
        'readers more control over their time.',
  );
  final Story placeholder = Story.placeholder();
  WebAnalyzer.cacheMap[WebAnalyzer.getKey(placeholder)] = WebInfo(
    title: placeholder.title,
    description: 'Be kind. Be curious. Share what you know.',
  );
}

/// Widget tests cover the Flutter chrome around native platform surfaces.
/// The browser engine/camera pixels belong to integration tests on devices.
Future<void> installScreenPlatformFakes() async {
  WebViewPlatform.instance = _GoldenWebViewPlatform();
  PackageInfo.setMockInitialValues(
    appName: 'Hacki',
    packageName: 'com.hacki',
    version: '4.0.0',
    buildNumber: '400',
    buildSignature: '',
  );
  installGoldenPathProvider();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter/platform_views'), (
        MethodCall call,
      ) async {
        if (call.method == 'create') {
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          final int id = arguments['id']! as int;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                MethodChannel('net.touchcapture.qr.flutterqrplus/qrview_$id'),
                (MethodCall cameraCall) async => switch (cameraCall.method) {
                  'toggleFlash' || 'getFlashInfo' => false,
                  'flipCamera' || 'getCameraInfo' => 0,
                  _ => null,
                },
              );
          return defaultTargetPlatform == TargetPlatform.android ? id : null;
        }
        if (call.method == 'resize') {
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          return <String, Object?>{
            'width': arguments['width'],
            'height': arguments['height'],
          };
        }
        return null;
      });
}

/// Shared cache managers retain their first path, so use a stable test-only
/// temporary directory rather than deleting it between individual scenarios.
void installGoldenPathProvider() {
  final Directory directory = Directory(
    '${Directory.systemTemp.path}/hacki-golden-screen-fixtures',
  )..createSync(recursive: true);
  for (final String name in <String>[
    Constants.logFilename,
    Constants.previousLogFileName,
  ]) {
    File('${directory.path}/$name').writeAsStringSync('');
  }
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.path,
      );
}

class _GoldenWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _GoldenNavigationDelegate(params);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _GoldenWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _GoldenWebViewWidget(params);
}

class _GoldenWebViewController extends PlatformWebViewController {
  _GoldenWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> reload() async {}
}

class _GoldenNavigationDelegate extends PlatformNavigationDelegate {
  _GoldenNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class _GoldenWebViewWidget extends PlatformWebViewWidget {
  _GoldenWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xffeeeeee),
    child: Center(child: Text('Native web view')),
  );
}
