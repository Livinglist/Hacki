import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';

part 'split_view_state.dart';

class SplitViewCubit extends Cubit<SplitViewState> with Loggable {
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

  void zoom() => emit(state.copyWith(expanded: !state.expanded));

  @override
  String get logIdentifier => '[SplitViewCubit]';
}
