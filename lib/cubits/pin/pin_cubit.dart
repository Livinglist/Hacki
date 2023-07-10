import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  PinCubit({
    PreferenceRepository? preferenceRepository,
    StoriesRepository? storiesRepository,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(PinState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;
  final StoriesRepository _storiesRepository;

  void init() {
    emit(PinState.init());
    _preferenceRepository.pinnedStoriesIds.then((List<int> ids) {
      emit(state.copyWith(pinnedStoriesIds: ids));

      _storiesRepository.fetchStoriesStream(ids: ids).listen(_onStoryFetched);
    }).whenComplete(() => emit(state.copyWith(status: Status.loaded)));
  }

  void pinStory(Story story) {
    if (!state.pinnedStoriesIds.contains(story.id)) {
      emit(
        state.copyWith(
          pinnedStoriesIds: <int>{story.id, ...state.pinnedStoriesIds}.toList(),
          pinnedStories: <Story>{story, ...state.pinnedStories}.toList(),
        ),
      );
      _preferenceRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
    }
  }

  void unpinStory(Story story) {
    emit(
      state.copyWith(
        pinnedStoriesIds: <int>[...state.pinnedStoriesIds]..remove(story.id),
        pinnedStories: <Story>[...state.pinnedStories]..remove(story),
      ),
    );
    _preferenceRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
  }

  void refresh() {
    if (state.status == Status.loading) return;
    init();
  }

  void _onStoryFetched(Story story) {
    emit(state.copyWith(pinnedStories: <Story>[...state.pinnedStories, story]));
  }
}
