import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

void main() {
  late _MockStorage storage;
  late _MockPreferenceCubit preferenceCubit;
  late StreamController<PreferenceState> preferenceStates;

  /// A loaded state where the back and forward buttons are their own group.
  final PreferenceState separate = PreferenceState.init()
      .copyWithPreference(const CombineHistoryButtonsPreference(val: false))
      .copyWith(status: Status.success);

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    preferenceStates = StreamController<PreferenceState>.broadcast();
    preferenceCubit = _MockPreferenceCubit();
    whenListen(
      preferenceCubit,
      preferenceStates.stream,
      initialState: PreferenceState.init(),
    );
  });

  tearDown(() => preferenceStates.close());

  ThreadNavigationButtonCubit buildCubit() =>
      ThreadNavigationButtonCubit(preferenceCubit: preferenceCubit);

  Future<void> emitPreferences(PreferenceState state) async {
    preferenceStates.add(state);
    await Future<void>.delayed(Duration.zero);
  }

  group('ThreadNavigationButtonCubit', () {
    test('starts both groups at their default positions', () {
      final ThreadNavigationButtonCubit cubit = buildCubit();

      expect(cubit.state.dx, defaultOffset.dx);
      expect(cubit.state.dy, defaultOffset.dy);
      expect(cubit.state.historyDx, defaultHistoryOffset.dx);
      expect(cubit.state.historyDy, defaultHistoryOffset.dy);
    });

    test('moves each group without affecting the other', () {
      final ThreadNavigationButtonCubit cubit = buildCubit()
        ..updateHistoryButtonPosition(200, 300);

      expect(cubit.state.historyDx, 200);
      expect(cubit.state.historyDy, 300);
      expect(cubit.state.dx, defaultOffset.dx);
      expect(cubit.state.dy, defaultOffset.dy);

      cubit.updateButtonPosition(40, 50);

      expect(cubit.state.dx, 40);
      expect(cubit.state.dy, 50);
      expect(cubit.state.historyDx, 200);
      expect(cubit.state.historyDy, 300);
    });

    test('remembers both positions', () {
      final ThreadNavigationButtonCubit cubit = buildCubit()
        ..updateButtonPosition(40, 50)
        ..updateHistoryButtonPosition(200, 300);

      final ThreadNavigationButtonState? restored = buildCubit().fromJson(
        cubit.toJson(cubit.state)!,
      );

      expect(restored, cubit.state);
    });

    test('restores a position saved before the history group existed', () {
      final ThreadNavigationButtonState? restored = buildCubit().fromJson(
        <String, dynamic>{'buttonPositionDx': 40.0, 'buttonPositionDy': 50.0},
      );

      expect(restored?.dx, 40);
      expect(restored?.dy, 50);
      expect(restored?.historyDx, defaultHistoryOffset.dx);
      expect(restored?.historyDy, defaultHistoryOffset.dy);
    });

    test(
      'keeps the history position while preferences are still loading',
      () async {
        final ThreadNavigationButtonCubit cubit = buildCubit()
          ..updateHistoryButtonPosition(200, 300);

        // Defaults ("combined") are emitted while stored values are read.
        await emitPreferences(
          PreferenceState.init().copyWith(status: Status.inProgress),
        );
        await emitPreferences(separate);

        expect(cubit.state.historyDx, 200);
        expect(cubit.state.historyDy, 300);
      },
    );

    test('resets the history position when the groups are combined', () async {
      final ThreadNavigationButtonCubit cubit = buildCubit();
      await emitPreferences(separate);
      cubit.updateHistoryButtonPosition(200, 300);

      await emitPreferences(
        separate.copyWithPreference(
          const CombineHistoryButtonsPreference(val: true),
        ),
      );

      expect(cubit.state.historyDx, defaultHistoryOffset.dx);
      expect(cubit.state.historyDy, defaultHistoryOffset.dy);
    });

    test('resets the history position when the buttons are hidden', () async {
      final ThreadNavigationButtonCubit cubit = buildCubit();
      await emitPreferences(separate);
      cubit.updateHistoryButtonPosition(200, 300);

      await emitPreferences(
        separate.copyWithPreference(const HistoryButtonsPreference(val: false)),
      );

      expect(cubit.state.historyDx, defaultHistoryOffset.dx);
      expect(cubit.state.historyDy, defaultHistoryOffset.dy);
    });

    test(
      'resets both positions when the skip buttons are turned off',
      () async {
        final ThreadNavigationButtonCubit cubit = buildCubit();
        await emitPreferences(separate);
        cubit
          ..updateButtonPosition(40, 50)
          ..updateHistoryButtonPosition(200, 300);

        await emitPreferences(
          separate.copyWithPreference(const SkipButtonsPreference(val: false)),
        );

        expect(cubit.state.dx, defaultOffset.dx);
        expect(cubit.state.dy, defaultOffset.dy);
        expect(cubit.state.historyDx, defaultHistoryOffset.dx);
        expect(cubit.state.historyDy, defaultHistoryOffset.dy);
      },
    );
  });
}
