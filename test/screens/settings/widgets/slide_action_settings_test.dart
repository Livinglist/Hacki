import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/settings/widgets/slide_action_settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../golden_test_utils.dart';

void main() {
  final List<(SlideAction, Preference<int>)> slots =
      <(SlideAction, Preference<int>)>[
        (
          SlideAction.upvote,
          LeadingActionPreference(val: SlideAction.goToRoot.index),
        ),
        (
          SlideAction.reply,
          SecondaryActionPreference(val: SlideAction.goToRoot.index),
        ),
        (
          SlideAction.timeMachine,
          TrailingActionPreference(val: SlideAction.goToRoot.index),
        ),
      ];

  for (final (SlideAction current, Preference<int> preference) in slots) {
    testWidgets('offers Go To Root for ${preference.key}', (
      WidgetTester tester,
    ) async {
      await tester.pumpGolden(
        const SlideActionSettings(),
        preferenceState: slidePreferenceState(),
        size: const Size(390, 844),
      );
      final PreferenceCubit cubit = tester
          .element(find.byType(SlideActionSettings))
          .read<PreferenceCubit>();

      await tester.tap(find.byIcon(current.icon));
      await tester.pumpAndSettle();
      final Finder rootAction = find.text(' Go To Root');
      expect(rootAction, findsOneWidget);
      await tester.ensureVisible(rootAction);
      await tester.tap(rootAction);
      await tester.pumpAndSettle();

      verify(() => cubit.update<int>(preference)).called(1);
    });
  }
}
