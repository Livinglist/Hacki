import 'dart:async';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_test_utils.dart';

const Key _childKey = Key('child');
const Size _size = Size(390, 72);

final Comment _comment = Comment(
  id: 1,
  time: 0,
  parent: 0,
  score: 0,
  by: 'pg',
  text: 'A comment',
  kids: const <int>[],
  dead: false,
  deleted: false,
  hidden: false,
  level: 0,
  isFromCache: false,
);

enum _Pane { start, end }

void main() {
  Future<void> pumpSlidable(
    WidgetTester tester, {
    required PreferenceState preferenceState,
    required _Pane open,
    String username = '',
    Set<SlideAction> unavailableActions = const <SlideAction>{},
  }) async {
    await tester.pumpGolden(
      Builder(
        builder: (BuildContext context) {
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          return ItemSlidable(
            item: _comment,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            unavailableActions: unavailableActions,
            onLeadingActionTapped: () {},
            onSecondaryActionTapped: () {},
            onTrailingActionTapped: () {},
            onEditTapped: () {},
            onMoreTapped: (_) {},
            child: Container(
              key: _childKey,
              height: _size.height,
              color: colorScheme.surface,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('pg: A comment'),
            ),
          );
        },
      ),
      preferenceState: preferenceState,
      size: _size,
      username: username,
    );

    final SlidableController controller = Slidable.of(
      tester.element(find.byKey(_childKey)),
    )!;
    switch (open) {
      case _Pane.start:
        unawaited(controller.openStartActionPane());
      case _Pane.end:
        unawaited(controller.openEndActionPane());
    }
    await tester.pumpAndSettle();
  }

  group('ItemSlidable', () {
    testWidgets('leading pane with default actions', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(),
        open: _Pane.start,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_leading_default.png'),
      );
    });

    testWidgets('trailing pane with default action', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(),
        open: _Pane.end,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_trailing_default.png'),
      );
    });

    testWidgets('leading pane moves to the right when swapped', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(swapped: true),
        open: _Pane.end,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_leading_swapped.png'),
      );
    });

    testWidgets('trailing pane moves to the left when swapped', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(swapped: true),
        open: _Pane.start,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_trailing_swapped.png'),
      );
    });

    testWidgets('leading pane with custom actions', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(
          leading: SlideAction.favorite,
          secondary: SlideAction.share,
        ),
        open: _Pane.start,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_leading_custom.png'),
      );
    });

    testWidgets('trailing pane with custom action', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(
          trailing: SlideAction.viewInBrowser,
        ),
        open: _Pane.end,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_trailing_custom.png'),
      );
    });

    testWidgets('own item hides vote actions and shows edit', (
      WidgetTester tester,
    ) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(),
        open: _Pane.start,
        username: _comment.by,
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_leading_own_item.png'),
      );
    });

    testWidgets('unavailable actions are hidden', (WidgetTester tester) async {
      await pumpSlidable(
        tester,
        preferenceState: slidePreferenceState(leading: SlideAction.goToParent),
        open: _Pane.start,
        unavailableActions: <SlideAction>{
          SlideAction.goToParent,
          SlideAction.timeMachine,
        },
      );

      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/item_slidable_leading_unavailable.png'),
      );
    });
  });
}
