import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';

part 'split_view_state.dart';

class SplitViewCubit extends Cubit<SplitViewState> {
  SplitViewCubit({CacheService? cacheService})
      : _cacheService = cacheService ?? locator.get<CacheService>(),
        super(const SplitViewState.init());

  final CacheService _cacheService;

  void updateStoryScreenArgs(StoryScreenArgs args) {
    _cacheService.resetCollapsedComments();
    emit(state.copyWith(storyScreenArgs: args));
  }

  void enableSplitView() => emit(state.copyWith(enabled: true));

  void disableSplitView() => emit(state.copyWith(enabled: false));

  void zoom() => emit(state.copyWith(expanded: !state.expanded));
}
