import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hacki/cubits/preference/preference_cubit.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'hide_state.dart';

class HideCubit extends HydratedCubit<HideState> {
  HideCubit({required PreferenceCubit preferenceCubit})
      : _preferenceCubit = preferenceCubit,
        super(HideState.init()) {
    init();
  }

  final PreferenceCubit _preferenceCubit;
  late final StreamSubscription<bool> _preferenceStateSubscription;

  static const int _maxCount = 500;

  void init() {
    _preferenceStateSubscription = _preferenceCubit.stream
        .distinct(
          (PreferenceState previous, PreferenceState current) =>
              previous.isHideInsteadOfMarkingGrayEnabled ==
              current.isHideInsteadOfMarkingGrayEnabled,
        )
        .map(
          (PreferenceState prefState) =>
              prefState.isHideInsteadOfMarkingGrayEnabled,
        )
        .listen((bool isHideInsteadOfMarkingGrayEnabled) {
      if (!isHideInsteadOfMarkingGrayEnabled) {
        clear();
        emit(HideState.init());
      }
    });
  }

  bool isHidden(int storyId) =>
      _preferenceCubit.state.isHideInsteadOfMarkingGrayEnabled &&
      state.hiddenStoryIds.contains(storyId);

  void hide(int storyId) {
    if (state.hiddenStoryIds.contains(storyId)) return;
    final List<int> updatedList = <int>[storyId, ...state.hiddenStoryIds];
    final HideState updatedState = state.copyWith(hiddenStoryIds: updatedList);
    emit(updatedState);
  }

  void removeAllHiddenStoryIds() {
    emit(state.copyWith(hiddenStoryIds: <int>[]));
  }

  @override
  HideState? fromJson(Map<String, dynamic> json) {
    final List<int> storyIds =
        (json['storyIds'] as List<dynamic>?)?.cast<int>() ?? <int>[];
    return HideState(hiddenStoryIds: storyIds);
  }

  @override
  Map<String, dynamic>? toJson(HideState state) {
    return <String, dynamic>{
      'storyIds': state.hiddenStoryIds.take(_maxCount).toList(),
    };
  }

  @override
  Future<void> close() {
    _preferenceStateSubscription.cancel();
    return super.close();
  }
}
