import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_platform_interface/method_channel_in_app_review.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MethodChannelInAppReview methodChannelInAppReview;
  late List<MethodCall> log = <MethodCall>[];
  const MethodChannel channel = MethodChannel('dev.britannio.in_app_review');

  setUp(() {
    methodChannelInAppReview = MethodChannelInAppReview();
    methodChannelInAppReview.channel = channel;
    log = <MethodCall>[];
  });

  tearDown(() {
    log.clear();
  });

  group('isAvailable', () {
    test(
      'should invoke the isAvailable method channel',
      () async {
        // ACT
        final bool result = await methodChannelInAppReview.isAvailable();

        // ASSERT
        expect(log, <Matcher>[isMethodCall('isAvailable', arguments: null)]);
        expect(result, isTrue);
      },
    );
  });

  group('requestReview', () {
    test(
      'should invoke the requestReview method channel',
      () async {
        // ACT
        await methodChannelInAppReview.requestReview();

        // ASSERT
        expect(log, <Matcher>[isMethodCall('requestReview', arguments: null)]);
      },
    );
  });

  group('openStoreListing', () {
    test(
      'should invoke the openStoreListing method channel on Android',
      () async {
        // ARRANGE
        methodChannelInAppReview.platform =
            FakePlatform(operatingSystem: 'android');

        // ACT
        await methodChannelInAppReview.openStoreListing();

        // ASSERT
        expect(
          log,
          <Matcher>[isMethodCall('openStoreListing', arguments: null)],
        );
      },
    );
    test(
      'should invoke the openStoreListing method channel on iOS',
      () async {
        // ARRANGE
        methodChannelInAppReview.platform =
            FakePlatform(operatingSystem: 'ios');
        final String appStoreId = "store_id";

        // ACT
        await methodChannelInAppReview.openStoreListing(appStoreId: appStoreId);

        // ASSERT
        expect(log,
            <Matcher>[isMethodCall('openStoreListing', arguments: appStoreId)]);
      },
    );
    test(
      'should invoke the openStoreListing method channel on MacOS',
      () async {
        // ARRANGE
        methodChannelInAppReview.platform =
            FakePlatform(operatingSystem: 'macos');
        final String appStoreId = "store_id";

        // ACT
        await methodChannelInAppReview.openStoreListing(appStoreId: appStoreId);

        // ASSERT
        expect(log,
            <Matcher>[isMethodCall('openStoreListing', arguments: appStoreId)]);
      },
    );
    test(
      'should invoke the openStoreListing method channel on Windows',
      () async {
        // ARRANGE
        methodChannelInAppReview.platform =
            FakePlatform(operatingSystem: 'windows');
        final String microsoftStoreId = 'store_id';

        // ACT
        await methodChannelInAppReview.openStoreListing(
          microsoftStoreId: microsoftStoreId,
        );

        // ASSERT
        expect(log, <Matcher>[
          isMethodCall('openStoreListing', arguments: microsoftStoreId)
        ]);
      },
      skip:
          'The windows uwp implementation still uses the url_launcher package',
    );
  });
}
