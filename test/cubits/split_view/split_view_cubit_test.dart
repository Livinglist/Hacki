import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

void main() {
  late _MockStorage storage;
  late _MockPreferenceCubit preferenceCubit;
  late StreamController<PreferenceState> preferences;

  PreferenceState preference({required bool splitView}) =>
      PreferenceState.init()
          .copyWithPreference(SplitViewPreference(val: splitView))
          .copyWith(status: Status.success);

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    preferences = StreamController<PreferenceState>.broadcast(sync: true);
    preferenceCubit = _MockPreferenceCubit();
    whenListen(
      preferenceCubit,
      preferences.stream,
      initialState: preference(splitView: true),
    );
  });

  tearDown(() => preferences.close());

  SplitViewCubit buildCubit() {
    final SplitViewCubit cubit = SplitViewCubit(
      preferenceCubit: preferenceCubit,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> emitPreference({required bool splitView}) async {
    preferences.add(preference(splitView: splitView));
    await Future<void>.delayed(Duration.zero);
  }

  test('restores split view every time the available window expands', () {
    final SplitViewCubit cubit = buildCubit()..updateWindowWidth(466);
    expect(cubit.state.enabled, isFalse);
    cubit.updateWindowWidth(890);
    expect(cubit.state.enabled, isTrue);
    cubit.updateWindowWidth(466);
    expect(cubit.state.enabled, isFalse);
    cubit.updateWindowWidth(626);
    expect(cubit.state.enabled, isTrue);
    expect(preferenceCubit.state.isSplitViewEnabled, isTrue);
  });

  test(
    'honors the loaded preference and applies changes without relaunch',
    () async {
      when(
        () => preferenceCubit.state,
      ).thenReturn(preference(splitView: false));
      final SplitViewCubit cubit = buildCubit()..updateWindowWidth(890);
      expect(cubit.state.enabled, isFalse);

      await emitPreference(splitView: true);
      expect(cubit.state.enabled, isTrue);
      await emitPreference(splitView: false);
      expect(cubit.state.enabled, isFalse);

      cubit
        ..updateWindowWidth(466)
        ..updateWindowWidth(890);
      expect(cubit.state.enabled, isFalse);
      await emitPreference(splitView: true);
      expect(cubit.state.enabled, isTrue);
    },
  );

  test('keeps the selected story while folding and returning to the feed', () {
    final SplitViewCubit cubit = buildCubit()..updateWindowWidth(890);
    final ItemScreenArgs args = ItemScreenArgs(item: Story.placeholder());
    cubit.updateItemScreenArgs(args);
    expect(cubit.state.showDetail, isTrue);

    cubit.updateWindowWidth(466);
    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.itemScreenArgs, same(args));
    expect(cubit.state.showDetail, isTrue);

    cubit.showStories();
    expect(cubit.state.showDetail, isFalse);
    expect(cubit.state.itemScreenArgs, same(args));
    cubit.updateWindowWidth(890);
    expect(cubit.state.enabled, isTrue);
    expect(cubit.state.itemScreenArgs, same(args));
  });

  test(
    'persists the preferred sidebar width without persisting window state',
    () {
      final SplitViewCubit cubit = buildCubit()
        ..updateWindowWidth(890)
        ..updateSubmissionPanelWidth(390);
      final Map<String, dynamic> saved = cubit.toJson(cubit.state)!;

      expect(saved, <String, dynamic>{'submissionPanelWidth': 390.0});
      final SplitViewState? restored = cubit.fromJson(saved);
      expect(restored?.submissionPanelWidth, 390);
    },
  );
}
