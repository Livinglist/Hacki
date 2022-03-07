import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'cache_state.dart';

class CacheCubit extends Cubit<CacheState> {
  CacheCubit({CacheRepository? cacheRepository})
      : _cacheRepository = cacheRepository ?? locator.get<CacheRepository>(),
        super(CacheState.init()) {
    init();
  }

  final CacheRepository _cacheRepository;

  void init() {
    _cacheRepository.getAllReadStoriesIds().then((allReadStories) {
      emit(state.copyWith(ids: allReadStories));
    });
  }

  void markStoryAsRead(int id) {
    emit(state.copyWithStoryMarkedAsRead(id: id));
    _cacheRepository.cacheReadStoryId(id: id);
  }

  void deleteAll() {
    emit(CacheState.init());
    _cacheRepository.deleteAllReadStoryIds();
  }
}
