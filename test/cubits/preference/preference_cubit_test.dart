import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    locator.registerSingleton<Logger>(MockLogger());
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async => locator.reset());

  Future<PreferenceCubit> loadCubit() async {
    final PreferenceCubit cubit = PreferenceCubit(
      preferenceRepository: PreferenceRepository(),
    );
    await cubit.stream.firstWhere(
      (PreferenceState state) => state.status == Status.success,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('persists order and visibility across preference reloads', () async {
    final PreferenceCubit original = await loadCubit();
    final List<ItemMenuAction> order = ItemMenuAction.values.reversed.toList();
    original
      ..updateItemMenuActions(order)
      ..setItemMenuActionEnabled(ItemMenuAction.share, enabled: false);

    final PreferenceCubit restored = await loadCubit();

    expect(restored.state.itemMenuActions, order);
    expect(
      restored.state.enabledItemMenuActions,
      isNot(contains(ItemMenuAction.share)),
    );
    expect(restored.state.enabledItemMenuActions.first, order.first);
  });

  test('menu reset restores every action and the default order', () async {
    final PreferenceCubit cubit = await loadCubit();
    cubit
      ..updateItemMenuActions(ItemMenuAction.values.reversed.toList())
      ..setItemMenuActionEnabled(ItemMenuAction.share, enabled: false)
      ..resetItemMenuActions();

    expect(cubit.state.itemMenuActions, ItemMenuAction.values);
    expect(cubit.state.enabledItemMenuActions, ItemMenuAction.values);
    expect(
      (await loadCubit()).state.enabledItemMenuActions,
      ItemMenuAction.values,
    );
  });

  test('restoring all settings also restores the item menu', () async {
    final PreferenceCubit cubit = await loadCubit();
    cubit
      ..setItemMenuActionEnabled(ItemMenuAction.share, enabled: false)
      ..restoreDefaultSettings();

    expect(cubit.state.itemMenuActions, ItemMenuAction.values);
    expect(cubit.state.enabledItemMenuActions, ItemMenuAction.values);
  });
}
