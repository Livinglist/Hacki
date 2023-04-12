import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final inAppReview = InAppReview.instance;
  late MockInAppReviewPlatform platform;

  setUp(() {
    platform = MockInAppReviewPlatform();
    InAppReviewPlatform.instance = platform;
  });

  tearDown(() {
    verifyNoMoreInteractions(platform);
  });

  group('isAvailable', () {
    test(
      'should call InAppReviewPlatform.isAvailable()',
      () async {
        // ARRANGE
        when(platform.isAvailable()).thenAnswer((_) async => true);

        // ACT
        final result = await inAppReview.isAvailable();

        // ASSERT
        verify(platform.isAvailable());
        expect(result, isTrue);
      },
    );
  });
  group('requestReview', () {
    test(
      'should call InAppReviewPlatform.requestReview()',
      () async {
        // ARRANGE
        when(platform.requestReview()).thenAnswer((_) async {});

        // ACT
        await inAppReview.requestReview();

        // ASSERT
        verify(platform.requestReview());
      },
    );
  });
  group('openStoreListing', () {
    test(
      'should call InAppReviewPlatform.openStoreListing()',
      () async {
        // ARRANGE
        const appStoreId = 'app_store_id';
        const microsoftStoreId = 'microsoft_store_id';
        when(platform.openStoreListing(
          appStoreId: appStoreId,
          microsoftStoreId: microsoftStoreId,
        )).thenAnswer((_) async {});

        // ACT
        await inAppReview.openStoreListing(
          appStoreId: appStoreId,
          microsoftStoreId: microsoftStoreId,
        );

        // ASSERT
        verify(platform.openStoreListing(
          appStoreId: appStoreId,
          microsoftStoreId: microsoftStoreId,
        ));
      },
    );
  });
}

class MockInAppReviewPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements InAppReviewPlatform {
  @override
  Future<bool> isAvailable() => super.noSuchMethod(
        Invocation.method(#isAvailable, null),
        returnValue: Future.value(true),
      );

  @override
  Future<void> requestReview() => super.noSuchMethod(
        Invocation.method(#requestReview, null),
        returnValue: Future<void>.value(),
      );

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #openStoreListing,
          null,
          {#appStoreId: appStoreId, #microsoftStoreId: microsoftStoreId},
        ),
        returnValue: Future<void>.value(),
      );
}
