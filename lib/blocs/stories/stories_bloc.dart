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
    loadTopStories(of: StoryType.top);
    loadTopStories(of: StoryType.latest);
    loadTopStories(of: StoryType.ask);
    loadTopStories(of: StoryType.show);
    loadTopStories(of: StoryType.jobs);

    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(onStoryLoaded);
  }

  final StoriesRepository _storiesRepository;
  static const _pageSize = 20;

  Future loadTopStories({required StoryType of}) async {
    final ids = await _storiesRepository.fetchTopStoryIds(of: of).then((ids) {
      emit(state.copyWithStoryIdsUpdated(of: of, to: ids));
      emit(state.copyWithCurrentPageUpdated(of: of, to: 0));
      return ids;
    });
    _storiesRepository
        .fetchStoriesStream(ids: ids.sublist(0, 20))
        .listen((story) {
      add(StoryLoaded(story: story, type: of));
    }).onDone(() {
      emit(state.copyWithStatusUpdated(of: of, to: StoriesStatus.loaded));
    });
  }

  void onInitialize(StoriesInitialize event, Emitter<StoriesState> emit) =>
      loadTopStories(of: event.type);

  void onRefresh(StoriesRefresh event, Emitter<StoriesState> emit) {
    emit(state.copyWithRefreshed(of: event.type));
    loadTopStories(of: event.type);
  }

  void onLoadMore(StoriesLoadMore event, Emitter<StoriesState> emit) {
    final currentPage = state.currentPageByType[event.type]!;
    final len = state.storyIdsByType[event.type]!.length;
    emit(state.copyWithCurrentPageUpdated(of: event.type, to: currentPage + 1));
    final lower = _pageSize * (currentPage + 1);
    var upper = _pageSize + _pageSize * (currentPage + 1);

    if (len > lower) {
      if (len > upper) {
        upper = len;
      }
      _storiesRepository
          .fetchStoriesStream(
              ids: state.storyIdsByType[event.type]!.sublist(
                  _pageSize * (currentPage + 1),
                  _pageSize + _pageSize * (currentPage + 1)))
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
}
