import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await app.main(testing: true);
    await tester.pumpWidget(
      const app.HackiApp(
        trueDarkMode: false,
      ),
    );

    final Finder listFinder = find.byType(Scrollable);
    final Finder itemFinder = find.widgetWithText(Tab, 'BEST');

    await binding.traceAction(
      () async {
        // Scroll until the item to be found appears.
        await tester.scrollUntilVisible(
          itemFinder,
          500,
          scrollable: listFinder,
        );
      },
      reportKey: 'scrolling_timeline',
    );
  });

  // group('performance test', () {
  //   testWidgets('scrolling performance on ItemScreen',
  //       (WidgetTester tester) async {
  //     await app.main(testing: true);
  //     await tester.pump();
  //
  //     final Finder bestStoryTabFinder = find.text('BEST');
  //
  //     await tester.tap(bestStoryTabFinder);
  //     await tester.pumpAndSettle(const Duration(seconds: 3));
  //
  //     final Finder storyTileFinder = find.byType(StoryTile);
  //
  //     await tester.tap(storyTileFinder.first);
  //     await tester.pumpAndSettle(const Duration(seconds: 3));
  //
  //     TestGesture gesture = await tester.startGesture(const Offset(0, 300));
  //     await gesture.moveBy(const Offset(0, -300));
  //     await tester.pump();
  //
  //     gesture = await tester.startGesture(const Offset(0, 300));
  //     await gesture.moveBy(const Offset(0, -300));
  //     await tester.pump();
  //
  //     gesture = await tester.startGesture(const Offset(0, 300));
  //     await gesture.moveBy(const Offset(0, -300));
  //     await tester.pump();
  //
  //     gesture = await tester.startGesture(const Offset(0, 300));
  //     await gesture.moveBy(const Offset(0, 900));
  //     await tester.pump();
  //
  //     gesture = await tester.startGesture(const Offset(0, 300));
  //     await gesture.moveBy(const Offset(0, -900));
  //     await tester.pump();
  //   });
  // });
}
