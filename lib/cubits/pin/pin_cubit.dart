import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  PinCubit({
    StorageRepository? storageRepository,
    StoriesRepository? storiesRepository,
  })  : _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(PinState.init()) {
    init();
  }

  final StorageRepository _storageRepository;
  final StoriesRepository _storiesRepository;

  void init() {
    _storageRepository.pinnedStoriesIds.then((ids) {
      emit(state.copyWith(pinnedStoriesIds: ids));

      _storiesRepository.fetchStoriesStream(ids: ids).listen(_onStoryFetched);
    });
  }

  void pinStory(Story story) {
    emit(state.copyWith(
      pinnedStoriesIds: {story.id, ...state.pinnedStoriesIds}.toList(),
      pinnedStories: {story, ...state.pinnedStories}.toList(),
    ));
    _storageRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
  }

  void unpinStory(Story story) {
    emit(state.copyWith(
      pinnedStoriesIds: [...state.pinnedStoriesIds]..remove(story.id),
      pinnedStories: [...state.pinnedStories]..remove(story),
    ));
    _storageRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
  }

  void _onStoryFetched(Story story) {
    emit(state.copyWith(pinnedStories: [...state.pinnedStories, story]));
  }
}
