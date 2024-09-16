import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/main.dart' as app;
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scrolling test', (WidgetTester tester) async {
    await app.main(testing: true);
    await tester.pumpAndSettle();

    final Finder bestTabFinder = find.widgetWithText(Tab, 'BEST');

    expect(bestTabFinder, findsOneWidget);

    Future<void> scrollDown(WidgetTester tester) async {
      await tester.timedDragFrom(
        const Offset(100, 200),
        const Offset(100, -700),
        const Duration(seconds: 2),
      );
      await tester.pump();
    }

    Future<void> scrollUp(WidgetTester tester) async {
      await tester.timedDragFrom(
        const Offset(100, 200),
        const Offset(100, 700),
        const Duration(seconds: 1),
      );
      await tester.pump();
    }

    await binding.traceAction(
      () async {
        await tester.tap(bestTabFinder);
        await tester.pump();

        const int count = 10;

        for (int i = 0; i < count; i++) {
          await scrollDown(tester);
        }

        for (int i = 0; i < count - 3; i++) {
          await scrollUp(tester);
        }

        await tester.pumpAndSettle(const Duration(seconds: 2));

        final Finder storyFinder = find.byType(StoryTile);

        expect(storyFinder, findsWidgets);

        final Finder firstStoryFinder = storyFinder.first;

        expect(firstStoryFinder, findsOneWidget);

        await tester.tap(firstStoryFinder);
        await tester.pump(const Duration(seconds: 5));
      },
      reportKey: 'scrolling_timeline',
    );
  });
}
