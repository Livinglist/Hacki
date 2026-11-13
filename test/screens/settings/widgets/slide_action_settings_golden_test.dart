import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/settings/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../golden_test_utils.dart';

const Size _size = Size(390, 96);

void expectActionOrder(WidgetTester tester, List<IconData> icons) {
  for (int i = 0; i < icons.length - 1; i++) {
    expect(
      tester.getCenter(find.byIcon(icons[i])).dx,
      lessThan(tester.getCenter(find.byIcon(icons[i + 1])).dx),
    );
  }
}

void main() {
  group('SlideActionSettings', () {
    testWidgets('default actions', (WidgetTester tester) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(),
        size: _size,
      );

      expectActionOrder(tester, <IconData>[
        SlideAction.upvote.icon,
        SlideAction.reply.icon,
        Icons.more_horiz,
        SlideAction.timeMachine.icon,
      ]);

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/slide_action_settings_default.png'),
      );
    });

    testWidgets('swapped panes reverse the three-button action order', (
      WidgetTester tester,
    ) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(swapped: true),
        size: _size,
      );

      expectActionOrder(tester, <IconData>[
        SlideAction.timeMachine.icon,
        Icons.more_horiz,
        SlideAction.reply.icon,
        SlideAction.upvote.icon,
      ]);
    });

    testWidgets('custom actions', (WidgetTester tester) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(
          leading: SlideAction.favorite,
          secondary: SlideAction.share,
          trailing: SlideAction.viewInBrowser,
        ),
        size: _size,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/slide_action_settings_custom.png'),
      );
    });

    testWidgets('dark theme', (WidgetTester tester) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(),
        size: _size,
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/slide_action_settings_dark.png'),
      );
    });

    testWidgets('menu highlights the current action', (
      WidgetTester tester,
    ) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(),
        size: const Size(390, 640),
      );

      await tester.tap(find.byIcon(SlideAction.upvote.icon));
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/slide_action_settings_menu_open.png'),
      );
    });
  });
}
