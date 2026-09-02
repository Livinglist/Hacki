import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'thread_navigation_button_state.dart';

class ThreadNavigationButtonCubit
    extends HydratedCubit<ThreadNavigationButtonState> {
  ThreadNavigationButtonCubit() : super(ThreadNavigationButtonState.init());

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
}
