import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';

part 'split_view_state.dart';

class SplitViewCubit extends Cubit<SplitViewState> {
  SplitViewCubit({
    CommentCache? commentCache,
    Logger? logger,
  })  : _commentCache = commentCache ?? locator.get<CommentCache>(),
        _logger = logger ?? locator.get<Logger>(),
        super(const SplitViewState.init());

  final Logger _logger;
  final CommentCache _commentCache;
  static const String _logPrefix = '[SplitViewCubit]';

  void updateItemScreenArgs(ItemScreenArgs args) {
    _logger.i('$_logPrefix resetting comments in CommentCache');
    _commentCache.resetComments();
    emit(state.copyWith(itemScreenArgs: args));
  }

  void enableSplitView() => emit(state.copyWith(enabled: true));

  void disableSplitView() => emit(state.copyWith(enabled: false));

  void zoom() => emit(state.copyWith(expanded: !state.expanded));
}
