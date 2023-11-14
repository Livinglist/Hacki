import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  PinCubit({
    PreferenceRepository? preferenceRepository,
    HackerNewsRepository? hackerNewsRepository,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        super(PinState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;
  final HackerNewsRepository _hackerNewsRepository;

  void init() {
    emit(PinState.init());
    _preferenceRepository.pinnedStoriesIds.then((List<int> ids) {
      emit(state.copyWith(pinnedStoriesIds: ids));

      _hackerNewsRepository
          .fetchStoriesStream(ids: ids)
          .listen(_onStoryFetched);
    }).whenComplete(() => emit(state.copyWith(status: Status.success)));
  }

  void pinStory(
    Story story, {
    VoidCallback? onDone,
  }) {
    if (!state.pinnedStoriesIds.contains(story.id)) {
      emit(
        state.copyWith(
          pinnedStoriesIds: <int>{story.id, ...state.pinnedStoriesIds}.toList(),
          pinnedStories: <Story>{story, ...state.pinnedStories}.toList(),
        ),
      );
      _preferenceRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
      onDone?.call();
    }
  }

  void unpinStory(
    Story story, {
    VoidCallback? onDone,
  }) {
    emit(
      state.copyWith(
        pinnedStoriesIds: <int>[...state.pinnedStoriesIds]..remove(story.id),
        pinnedStories: <Story>[...state.pinnedStories]..remove(story),
      ),
    );
    _preferenceRepository.updatePinnedStoriesIds(state.pinnedStoriesIds);
    onDone?.call();
  }

  void refresh() {
    if (state.status.isLoading) return;
    init();
  }

  void _onStoryFetched(Story story) {
    emit(state.copyWith(pinnedStories: <Story>[...state.pinnedStories, story]));
  }
}
