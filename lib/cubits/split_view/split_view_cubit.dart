import 'package:equatable/equatable.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'split_view_state.dart';

class SplitViewCubit extends HydratedCubit<SplitViewState> with Loggable {
  SplitViewCubit({
    CommentCache? commentCache,
  })  : _commentCache = commentCache ?? locator.get<CommentCache>(),
        super(const SplitViewState.init());

  final CommentCache _commentCache;

  void updateItemScreenArgs(ItemScreenArgs args) {
    logInfo('resetting comments in CommentCache');
    _commentCache.resetComments();
    emit(state.copyWith(itemScreenArgs: args));
  }

  void enableSplitView() => emit(state.copyWith(enabled: true));

  void disableSplitView() => emit(state.copyWith(enabled: false));

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
  String get logIdentifier => '[SplitViewCubit]';

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
}
