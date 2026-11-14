import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'split_view_state.dart';

class SplitViewCubit extends HydratedCubit<SplitViewState> with Loggable {
  SplitViewCubit({required PreferenceCubit preferenceCubit})
    : _preferenceCubit = preferenceCubit,
      _splitViewPreferred = preferenceCubit.state.isSplitViewEnabled,
      super(const SplitViewState.init()) {
    init();
  }

  static const double minimumSplitViewWidth = 600;

  final PreferenceCubit _preferenceCubit;
  bool _splitViewPreferred;
  bool _hasWideWindow = false;
  late final StreamSubscription<bool> _preferenceStateSubscription;

  void init() {
    _preferenceStateSubscription = _preferenceCubit.stream
        .map((PreferenceState state) => state.isSplitViewEnabled)
        .distinct()
        .listen((bool preferred) {
          _splitViewPreferred = preferred;
          _updateEnabled();
        });
  }

  /// Re-evaluates the layout whenever the available window width changes.
  void updateWindowWidth(double width) {
    _hasWideWindow = width >= minimumSplitViewWidth;
    _updateEnabled();
  }

  void _updateEnabled() {
    final bool enabled = _hasWideWindow && _splitViewPreferred;
    final bool revealSelectedStory =
        state.enabled && !enabled && state.itemScreenArgs != null;
    emit(
      state.copyWith(
        enabled: enabled,
        showDetail: revealSelectedStory || state.showDetail,
      ),
    );
  }

  void updateItemScreenArgs(ItemScreenArgs args) {
    emit(state.copyWith(itemScreenArgs: args, showDetail: true));
  }

  /// Returns to the compact story list without discarding the selected thread.
  void showStories() =>
      emit(state.copyWith(showDetail: false, expanded: false));

  void zoom() => emit(
    state.copyWith(
      expanded: !state.expanded,
      resizingAnimationDuration: AppDurations.ms300,
    ),
  );

  void updateSubmissionPanelWidth(double width) => emit(
    state.copyWith(
      submissionPanelWidth: width,
      resizingAnimationDuration: Duration.zero,
    ),
  );

  @override
  String get logIdentifier => 'SplitViewCubit';

  static const String _submissionPanelWidthKey = 'submissionPanelWidth';

  @override
  SplitViewState? fromJson(Map<String, dynamic> json) {
    return state.copyWith(
      submissionPanelWidth: json[_submissionPanelWidthKey] as double?,
    );
  }

  @override
  Map<String, dynamic>? toJson(SplitViewState state) {
    return <String, dynamic>{
      _submissionPanelWidthKey: state.submissionPanelWidth,
    };
  }

  @override
  Future<void> close() {
    _preferenceStateSubscription.cancel();
    return super.close();
  }
}
