import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'thread_navigation_button_state.dart';

class ThreadNavigationButtonCubit
    extends HydratedCubit<ThreadNavigationButtonState> {
  ThreadNavigationButtonCubit({required PreferenceCubit preferenceCubit})
    : _preferenceCubit = preferenceCubit,
      super(ThreadNavigationButtonState.init()) {
    _areSkipButtonsEnabledStreamSubscription = _preferenceCubit.stream
        .map((PreferenceState s) => s.areSkipButtonsEnabled)
        .distinct()
        .listen((bool enabled) {
          if (!enabled) {
            updateButtonPosition(defaultOffset.dx, defaultOffset.dy);
          }
        });

    /// Preferences hold their default values while they are being loaded,
    /// so wait until loading is done before reacting to them.
    _areHistoryButtonsSeparateStreamSubscription = _preferenceCubit.stream
        .where((PreferenceState s) => s.status != Status.inProgress)
        .map(
          (PreferenceState s) =>
              s.areSkipButtonsEnabled && s.areHistoryButtonsSeparate,
        )
        .distinct()
        .listen((bool separate) {
          if (!separate) {
            updateHistoryButtonPosition(
              defaultHistoryOffset.dx,
              defaultHistoryOffset.dy,
            );
          }
        });
  }

  final PreferenceCubit _preferenceCubit;
  late final StreamSubscription<bool> _areSkipButtonsEnabledStreamSubscription;
  late final StreamSubscription<bool>
  _areHistoryButtonsSeparateStreamSubscription;

  void updateButtonPosition(double dx, double dy) =>
      emit(state.copyWith(dx: dx, dy: dy));

  void updateHistoryButtonPosition(double dx, double dy) =>
      emit(state.copyWith(historyDx: dx, historyDy: dy));

  static const String _buttonPositionDxKey = 'buttonPositionDx';
  static const String _buttonPositionDyKey = 'buttonPositionDy';
  static const String _historyButtonPositionDxKey = 'historyButtonPositionDx';
  static const String _historyButtonPositionDyKey = 'historyButtonPositionDy';

  @override
  ThreadNavigationButtonState? fromJson(Map<String, dynamic> json) {
    return state.copyWith(
      dx: json[_buttonPositionDxKey] as double? ?? defaultOffset.dx,
      dy: json[_buttonPositionDyKey] as double? ?? defaultOffset.dy,
      historyDx:
          json[_historyButtonPositionDxKey] as double? ??
          defaultHistoryOffset.dx,
      historyDy:
          json[_historyButtonPositionDyKey] as double? ??
          defaultHistoryOffset.dy,
    );
  }

  @override
  Map<String, dynamic>? toJson(ThreadNavigationButtonState state) {
    return <String, dynamic>{
      _buttonPositionDxKey: state.dx,
      _buttonPositionDyKey: state.dy,
      _historyButtonPositionDxKey: state.historyDx,
      _historyButtonPositionDyKey: state.historyDy,
    };
  }

  @override
  Future<void> close() {
    _areSkipButtonsEnabledStreamSubscription.cancel();
    _areHistoryButtonsSeparateStreamSubscription.cancel();
    return super.close();
  }
}
