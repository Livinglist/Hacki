import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:hacki/cubits/cubits.dart';
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
  }

  final PreferenceCubit _preferenceCubit;
  late final StreamSubscription<bool> _areSkipButtonsEnabledStreamSubscription;

  void updateButtonPosition(double dx, double dy) =>
      emit(state.copyWith(dx: dx, dy: dy));

  static const String _buttonPositionDxKey = 'buttonPositionDx';
  static const String _buttonPositionDyKey = 'buttonPositionDy';

  @override
  ThreadNavigationButtonState? fromJson(Map<String, dynamic> json) {
    return state.copyWith(
      dx: json[_buttonPositionDxKey] as double? ?? defaultOffset.dx,
      dy: json[_buttonPositionDyKey] as double? ?? defaultOffset.dy,
    );
  }

  @override
  Map<String, dynamic>? toJson(ThreadNavigationButtonState state) {
    return <String, dynamic>{
      _buttonPositionDxKey: state.dx,
      _buttonPositionDyKey: state.dy,
    };
  }

  @override
  Future<void> close() {
    _areSkipButtonsEnabledStreamSubscription.cancel();
    return super.close();
  }
}
