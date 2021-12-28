import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'stories_event.dart';

part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc({
    StoriesRepository? storiesRepository,
  })  : _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(const StoriesState.init()) {
    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(onStoryLoaded);
    on<StoriesLoaded>(onStoriesLoaded);
    add(StoriesInitialize());
  }

  final StoriesRepository _storiesRepository;
  static const _pageSize = 20;

  Future<void> loadTopStories(
      {required StoryType of, required Emitter<StoriesState> emit}) async {
    final ids = await _storiesRepository.fetchStoryIds(of: of);
    emit(state
        .copyWithStoryIdsUpdated(of: of, to: ids)
        .copyWithCurrentPageUpdated(of: of, to: 0));
    _storiesRepository
        .fetchStoriesStream(ids: ids.sublist(0, 20))
        .listen((story) {
      add(StoryLoaded(story: story, type: of));
    }).onDone(() {
      add(StoriesLoaded(type: of));
    });
  }

  Future<void> onInitialize(
      StoriesInitialize event, Emitter<StoriesState> emit) async {
    await loadTopStories(of: StoryType.top, emit: emit);
    await loadTopStories(of: StoryType.latest, emit: emit);
    await loadTopStories(of: StoryType.ask, emit: emit);
    await loadTopStories(of: StoryType.show, emit: emit);
    await loadTopStories(of: StoryType.jobs, emit: emit);
  }

  Future<void> onRefresh(
      StoriesRefresh event, Emitter<StoriesState> emit) async {
    emit(state.copyWithRefreshed(of: event.type));
    await loadTopStories(of: event.type, emit: emit);
  }

  void onLoadMore(StoriesLoadMore event, Emitter<StoriesState> emit) {
    final currentPage = state.currentPageByType[event.type]!;
    final len = state.storyIdsByType[event.type]!.length;
    emit(state.copyWithCurrentPageUpdated(of: event.type, to: currentPage + 1));
    final lower = _pageSize * (currentPage + 1);
    var upper = _pageSize + _pageSize * (currentPage + 1);

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      _storiesRepository
          .fetchStoriesStream(
              ids: state.storyIdsByType[event.type]!.sublist(
        lower,
        upper,
      ))
          .listen((story) {
        add(StoryLoaded(
          story: story,
          type: event.type,
        ));
      });
    }
  }

  void onStoryLoaded(StoryLoaded event, Emitter<StoriesState> emit) {
    emit(state.copyWithStoryAdded(of: event.type, story: event.story));
    if (state.storiesByType[event.type]!.length % _pageSize == 0) {
      emit(
        state.copyWithStatusUpdated(
          of: event.type,
          to: StoriesStatus.loaded,
        ),
      );
    }
  }

  void onStoriesLoaded(StoriesLoaded event, Emitter<StoriesState> emit) {
    emit(state.copyWithStatusUpdated(of: event.type, to: StoriesStatus.loaded));
  }
}
