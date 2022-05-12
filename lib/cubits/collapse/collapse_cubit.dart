import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/services/services.dart';

part 'collapse_state.dart';

class CollapseCubit extends Cubit<CollapseState> {
  CollapseCubit({
    required int commentId,
    CacheService? cacheService,
  })  : _commentId = commentId,
        _cacheService = cacheService ?? locator.get<CacheService>(),
        super(const CollapseState.init());

  final int _commentId;
  final CacheService _cacheService;

  void init() {
    emit(
      state.copyWith(
        collapsed: _cacheService.isCollapsed(_commentId),
      ),
    );
  }

  void collapse() {
    _cacheService.updateCollapsedComments(_commentId);
    emit(
      state.copyWith(
        collapsed: !state.collapsed,
      ),
    );
  }
}
