import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:responsive_builder/responsive_builder.dart';

part 'stories_event.dart';
part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc({
    required PreferenceCubit preferenceCubit,
    CacheRepository? cacheRepository,
    StoriesRepository? storiesRepository,
  })  : _preferenceCubit = preferenceCubit,
        _cacheRepository = cacheRepository ?? locator.get<CacheRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(const StoriesState.init()) {
    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(onStoryLoaded);
    on<StoriesLoaded>(onStoriesLoaded);
    on<StoriesDownload>(onDownload);
    on<StoriesExitOffline>(onExitOffline);
    on<StoriesPageSizeChanged>(onPageSizeChanged);
  }

  final PreferenceCubit _preferenceCubit;
  final CacheRepository _cacheRepository;
  final StoriesRepository _storiesRepository;
  late final DeviceScreenType deviceScreenType;
  StreamSubscription? _streamSubscription;
  static const _smallPageSize = 10;
  static const _largePageSize = 20;
  static const _tabletSmallPageSize = 15;
  static const _tabletLargePageSize = 25;

  Future<void> onInitialize(
      StoriesInitialize event, Emitter<StoriesState> emit) async {
    _streamSubscription ??= _preferenceCubit.stream.listen((event) {
      final isComplexTile = event.showComplexStoryTile;
      final pageSize = _getPageSize(isComplexTile: isComplexTile);

      if (pageSize != state.currentPageSize) {
        add(StoriesPageSizeChanged(pageSize: pageSize));
      }
    });
    final hasCachedStories = await _cacheRepository.hasCachedStories;
    final isComplexTile = _preferenceCubit.state.showComplexStoryTile;
    final pageSize = _getPageSize(isComplexTile: isComplexTile);
    emit(state.copyWith(
      offlineReading: hasCachedStories,
      currentPageSize: pageSize,
    ));
    await loadStories(of: StoryType.top, emit: emit);
    await loadStories(of: StoryType.latest, emit: emit);
    await loadStories(of: StoryType.ask, emit: emit);
    await loadStories(of: StoryType.show, emit: emit);
    await loadStories(of: StoryType.jobs, emit: emit);
  }

  Future<void> loadStories(
      {required StoryType of, required Emitter<StoriesState> emit}) async {
    if (state.offlineReading) {
      final ids = await _cacheRepository.getCachedStoryIds(of: of);
      emit(state
          .copyWithStoryIdsUpdated(of: of, to: ids)
          .copyWithCurrentPageUpdated(of: of, to: 0));
      _cacheRepository
          .getCachedStoriesStream(
              ids: ids.sublist(0, min(ids.length, state.currentPageSize)))
          .listen((story) {
        add(StoryLoaded(story: story, type: of));
      }).onDone(() {
        add(StoriesLoaded(type: of));
      });
    } else {
      final ids = await _storiesRepository.fetchStoryIds(of: of);
      emit(state
          .copyWithStoryIdsUpdated(of: of, to: ids)
          .copyWithCurrentPageUpdated(of: of, to: 0));
      _storiesRepository
          .fetchStoriesStream(ids: ids.sublist(0, state.currentPageSize))
          .listen((story) {
        add(StoryLoaded(story: story, type: of));
      }).onDone(() {
        add(StoriesLoaded(type: of));
      });
    }
  }

  Future<void> onRefresh(
      StoriesRefresh event, Emitter<StoriesState> emit) async {
    emit(state.copyWithStatusUpdated(
      of: event.type,
      to: StoriesStatus.loading,
    ));

    if (state.offlineReading) {
      emit(state.copyWithStatusUpdated(
        of: event.type,
        to: StoriesStatus.loaded,
      ));
    } else {
      emit(state.copyWithRefreshed(of: event.type));
      await loadStories(of: event.type, emit: emit);
    }
  }

  void onLoadMore(StoriesLoadMore event, Emitter<StoriesState> emit) {
    emit(state.copyWithStatusUpdated(
      of: event.type,
      to: StoriesStatus.loading,
    ));

    final currentPage = state.currentPageByType[event.type]!;
    final len = state.storyIdsByType[event.type]!.length;
    emit(state.copyWithCurrentPageUpdated(of: event.type, to: currentPage + 1));
    final currentPageSize = state.currentPageSize;
    final lower = currentPageSize * (currentPage + 1);
    var upper = currentPageSize + lower;

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      if (state.offlineReading) {
        _cacheRepository
            .getCachedStoriesStream(
                ids: state.storyIdsByType[event.type]!.sublist(
          lower,
          upper,
        ))
            .listen((story) {
          add(StoryLoaded(
            story: story,
            type: event.type,
          ));
        }).onDone(() {
          add(StoriesLoaded(type: event.type));
        });
      } else {
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
        }).onDone(() {
          add(StoriesLoaded(type: event.type));
        });
      }
    } else {
      emit(state.copyWithStatusUpdated(
          of: event.type, to: StoriesStatus.loaded));
    }
  }

  void onStoryLoaded(StoryLoaded event, Emitter<StoriesState> emit) {
    emit(state.copyWithStoryAdded(of: event.type, story: event.story));
  }

  void onStoriesLoaded(StoriesLoaded event, Emitter<StoriesState> emit) {
    emit(state.copyWithStatusUpdated(of: event.type, to: StoriesStatus.loaded));
  }

  Future<void> onDownload(
      StoriesDownload event, Emitter<StoriesState> emit) async {
    emit(state.copyWith(
      downloadStatus: StoriesDownloadStatus.downloading,
    ));

    await _cacheRepository.deleteAllStoryIds();
    await _cacheRepository.deleteAllStories();
    await _cacheRepository.deleteAllComments();

    final topIds = await _storiesRepository.fetchStoryIds(of: StoryType.top);
    final newIds = await _storiesRepository.fetchStoryIds(of: StoryType.latest);
    final askIds = await _storiesRepository.fetchStoryIds(of: StoryType.ask);
    final showIds = await _storiesRepository.fetchStoryIds(of: StoryType.show);
    final jobIds = await _storiesRepository.fetchStoryIds(of: StoryType.jobs);

    await _cacheRepository.cacheStoryIds(of: StoryType.top, ids: topIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.latest, ids: newIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.ask, ids: askIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.show, ids: showIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.jobs, ids: jobIds);

    final allIds = [...topIds, ...newIds, ...askIds, ...showIds, ...jobIds];

    try {
      _storiesRepository.fetchStoriesStream(ids: allIds).listen((story) async {
        if (story.kids.isNotEmpty) {
          await _cacheRepository.cacheStory(story: story);
          _storiesRepository
              .fetchAllChildrenComments(ids: story.kids)
              .listen((comment) async {
            if (comment != null) {
              await _cacheRepository.cacheComment(comment: comment);
            }
          });
        }
      }).onDone(() {
        emit(state.copyWith(
          downloadStatus: StoriesDownloadStatus.finished,
        ));
      });
    } catch (_) {
      emit(state.copyWith(
        downloadStatus: StoriesDownloadStatus.failure,
      ));
    }
  }

  Future<void> onPageSizeChanged(
      StoriesPageSizeChanged event, Emitter<StoriesState> emit) async {
    emit(const StoriesState.init());
    add(StoriesInitialize());
  }

  Future<void> onExitOffline(
      StoriesExitOffline event, Emitter<StoriesState> emit) async {
    await _cacheRepository.deleteAllStoryIds();
    await _cacheRepository.deleteAllStories();
    await _cacheRepository.deleteAllComments();
    emit(state.copyWith(offlineReading: false));
    add(StoriesInitialize());
  }

  int _getPageSize({required bool isComplexTile}) {
    var pageSize = isComplexTile ? _smallPageSize : _largePageSize;

    if (deviceScreenType == DeviceScreenType.tablet) {
      pageSize = isComplexTile ? _tabletSmallPageSize : _tabletLargePageSize;
    }

    return pageSize;
  }
}
