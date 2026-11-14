import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart' as app;
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture actual iPhone Duo display transitions', (
    WidgetTester tester,
  ) async {
    int nativeCaptures = 0;
    binding.reportData = <String, dynamic>{'nativeCaptures': nativeCaptures};
    // Native preferences only dismiss first-run UI. Content and window metrics
    // come from the running app and the real simulator, without fixtures.
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('tour', true);
    for (final Tips tip in Tips.values) {
      await preferences.setBool('${tip.name}_tips_completed', true);
    }
    await app.main(testing: true);

    Future<void> waitFor(bool Function() ready, String reason) async {
      final DateTime deadline = DateTime.now().add(
        const Duration(seconds: 120),
      );
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(ready(), isTrue, reason: reason);
      await tester.pump(const Duration(seconds: 2));
      // A resize updates SplitViewCubit after layout; paint its new state too.
      await tester.pump();
      await tester.pump();
    }

    Size windowSize() =>
        tester.view.physicalSize / tester.view.devicePixelRatio;

    Future<void> capture(String name, {String? nextPose}) async {
      final HttpClient client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final DateTime deadline = DateTime.now().add(
          const Duration(seconds: 30),
        );
        HttpClientRequest? request;
        while (request == null) {
          try {
            request = await client.postUrl(
              Uri.parse(
                'http://127.0.0.1:${const int.fromEnvironment('DUO_CAPTURE_PORT', defaultValue: 8765)}/capture',
              ),
            );
          } on SocketException {
            if (DateTime.now().isAfter(deadline)) rethrow;
            await Future<void>.delayed(const Duration(milliseconds: 250));
          }
        }
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode(<String, Object?>{
            'name': name,
            'nextPose': nextPose,
            'logicalWidth': windowSize().width,
            'logicalHeight': windowSize().height,
            'devicePixelRatio': tester.view.devicePixelRatio,
            'physicalWidth': tester.view.physicalSize.width,
            'physicalHeight': tester.view.physicalSize.height,
            'viewPadding': <String, double>{
              'left': tester.view.viewPadding.left,
              'top': tester.view.viewPadding.top,
              'right': tester.view.viewPadding.right,
              'bottom': tester.view.viewPadding.bottom,
            },
          }),
        );
        final HttpClientResponse response = await request.close().timeout(
          const Duration(seconds: 60),
        );
        final String body = await utf8.decoder.bind(response).join();
        expect(response.statusCode, HttpStatus.ok, reason: body);
        nativeCaptures++;
        binding.reportData = <String, dynamic>{
          ...binding.reportData!,
          'nativeCaptures': nativeCaptures,
          'lastCapture': name,
        };
      } finally {
        client.close(force: true);
      }
    }

    final Finder stories = find.byType(StoryTile);
    await waitFor(
      () => stories.evaluate().isNotEmpty,
      'Public HN stories should load',
    );
    final SplitViewCubit splitView = tester
        .element(stories.first)
        .read<SplitViewCubit>();
    expect(windowSize().width, lessThan(SplitViewCubit.minimumSplitViewWidth));
    expect(splitView.state.enabled, isFalse);
    await capture('01-folded-feed', nextPose: 'open');

    await waitFor(
      () =>
          windowSize().width >= SplitViewCubit.minimumSplitViewWidth &&
          splitView.state.enabled,
      'Opening the physical simulator should resize the actual app window',
    );
    final Finder storyWithComments = find.byWidgetPredicate(
      (Widget widget) => widget is StoryTile && widget.story.descendants > 0,
    );
    expect(storyWithComments, findsWidgets);
    await tester.tap(storyWithComments.first);
    await waitFor(
      () => find.byType(CommentTile).evaluate().isNotEmpty,
      'The selected live HN thread should load comments',
    );
    final BuildContext detailContext = tester.element(find.byType(ItemScreen));
    final CommentsCubit comments = detailContext.read<CommentsCubit>();
    final int selectedStoryId = comments.state.item.id;
    binding.reportData = <String, dynamic>{
      ...binding.reportData!,
      'selectedStoryId': selectedStoryId,
    };
    final Size unfoldedSize = windowSize();
    await capture('02-unfolded-thread', nextPose: 'rotate');

    await waitFor(
      () => windowSize() != unfoldedSize,
      'Rotating the simulator should change actual window metrics',
    );
    expect(identical(detailContext.read<CommentsCubit>(), comments), isTrue);
    await capture('03-unfolded-rotated-thread', nextPose: 'close');

    await waitFor(
      () =>
          windowSize().width < SplitViewCubit.minimumSplitViewWidth &&
          !splitView.state.enabled,
      'Closing the simulator should return to the outer display',
    );
    expect(find.byTooltip('Back to stories'), findsOneWidget);
    expect(comments.state.item.id, selectedStoryId);
    expect(
      identical(
        tester.element(find.byType(ItemScreen)).read<CommentsCubit>(),
        comments,
      ),
      isTrue,
    );
    await capture('04-refolded-thread');
    await tester.tap(find.byTooltip('Back to stories'));
    await waitFor(
      () => stories.evaluate().isNotEmpty,
      'Returning from the selected thread should reveal the feed',
    );
    await capture('05-refolded-feed');
    expect(nativeCaptures, 5);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
