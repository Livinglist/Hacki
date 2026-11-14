import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/settings/item_menu_settings_screen.dart';
import 'package:hacki/screens/settings/widgets/slide_action_settings.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

void main() {
  late PreferenceCubit cubit;

  setUpAll(() {
    locator.registerSingleton<Logger>(MockLogger());
  });

  tearDownAll(locator.reset);

  setUp(() async {
    HapticFeedbackUtils.enabled = false;
    final MockPreferenceRepository repository = MockPreferenceRepository();
    when(() => repository.getBool(any())).thenAnswer((_) async => null);
    when(() => repository.getInt(any())).thenAnswer((_) async => null);
    when(() => repository.getDouble(any())).thenAnswer((_) async => null);
    when(() => repository.getString(any())).thenAnswer((_) async => null);
    cubit = PreferenceCubit(preferenceRepository: repository);
    await cubit.stream.firstWhere(
      (PreferenceState state) => state.status == Status.success,
    );
  });

  tearDown(() async {
    await cubit.close();
    HapticFeedbackUtils.enabled = true;
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    Widget child = const ItemMenuSettingsScreen(),
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme(
          ColorScheme.fromSeed(seedColor: Palette.deepOrange),
          Font.robotoSlab,
          isDarkModeEnabled: false,
          isTrueDarkModeEnabled: false,
        ),
        home: BlocProvider<PreferenceCubit>.value(value: cubit, child: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder actionRow(ItemMenuAction action) =>
      find.byKey(ValueKey<ItemMenuAction>(action));

  Finder actionSwitch(ItemMenuAction action) =>
      find.descendant(of: actionRow(action), matching: find.byType(Switch));

  testWidgets('more opens customization and retains changes when reopened', (
    WidgetTester tester,
  ) async {
    await pumpSettings(
      tester,
      child: const Scaffold(body: SlideActionSettings()),
    );

    await tester.tap(find.byTooltip('Customize item actions'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemMenuSettingsScreen), findsOneWidget);

    await tester.tap(actionSwitch(ItemMenuAction.viewProfile));
    await tester.pumpAndSettle();
    expect(
      cubit.state.enabledItemMenuActions,
      isNot(contains(ItemMenuAction.viewProfile)),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Customize item actions'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Switch>(actionSwitch(ItemMenuAction.viewProfile)).value,
      isFalse,
    );
  });

  testWidgets('dragging a handle changes the action order', (
    WidgetTester tester,
  ) async {
    await pumpSettings(tester);

    await tester.timedDrag(
      find.byTooltip('Reorder View Profile'),
      const Offset(0, 70),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.itemMenuActions[0], ItemMenuAction.searchOnHackerNews);
    expect(cubit.state.itemMenuActions[1], ItemMenuAction.viewProfile);
    expect(
      tester.getTopLeft(actionRow(ItemMenuAction.searchOnHackerNews)).dy,
      lessThan(tester.getTopLeft(actionRow(ItemMenuAction.viewProfile)).dy),
    );
  });

  testWidgets('toggling retains position and reset restores all defaults', (
    WidgetTester tester,
  ) async {
    final List<ItemMenuAction> reordered = <ItemMenuAction>[
      ItemMenuAction.reply,
      ...ItemMenuAction.values.where(
        (ItemMenuAction action) => action != ItemMenuAction.reply,
      ),
    ];
    cubit.updateItemMenuActions(reordered);
    await pumpSettings(tester);

    await tester.tap(actionSwitch(ItemMenuAction.reply));
    await tester.pumpAndSettle();
    expect(cubit.state.itemMenuActions, reordered);
    expect(
      tester.widget<Switch>(actionSwitch(ItemMenuAction.reply)).value,
      isFalse,
    );
    await tester.tap(actionSwitch(ItemMenuAction.reply));
    await tester.pumpAndSettle();
    expect(cubit.state.itemMenuActions, reordered);
    expect(cubit.state.enabledItemMenuActions, contains(ItemMenuAction.reply));

    cubit.setItemMenuActionEnabled(ItemMenuAction.reply, enabled: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reset item actions'));
    await tester.pumpAndSettle();
    expect(cubit.state.itemMenuActions, ItemMenuAction.values);
    expect(cubit.state.enabledItemMenuActions, ItemMenuAction.values);
  });

  testWidgets('all actions remain reachable on a small screen', (
    WidgetTester tester,
  ) async {
    await pumpSettings(tester, size: const Size(320, 568));

    await tester.scrollUntilVisible(
      actionRow(ItemMenuAction.viewInBrowser),
      200,
    );
    expect(actionSwitch(ItemMenuAction.viewInBrowser), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
