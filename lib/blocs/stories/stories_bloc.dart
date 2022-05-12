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
    PreferenceRepository? preferenceRepository,
  })  : _preferenceCubit = preferenceCubit,
        _cacheRepository = cacheRepository ?? locator.get<CacheRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(const StoriesState.init()) {
    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(onStoryLoaded);
    on<StoryRead>(onStoryRead);
    on<StoriesLoaded>(onStoriesLoaded);
    on<StoriesDownload>(onDownload);
    on<StoriesExitOffline>(onExitOffline);
    on<StoriesPageSizeChanged>(onPageSizeChanged);
    on<ClearAllReadStories>(onClearAllReadStories);
  }

  final PreferenceCubit _preferenceCubit;
  final CacheRepository _cacheRepository;
  final StoriesRepository _storiesRepository;
  final PreferenceRepository _preferenceRepository;
  DeviceScreenType? deviceScreenType;
  StreamSubscription<PreferenceState>? _streamSubscription;
  static const int _smallPageSize = 10;
  static const int _largePageSize = 20;
  static const int _tabletSmallPageSize = 15;
  static const int _tabletLargePageSize = 25;

  Future<void> onInitialize(
    StoriesInitialize event,
    Emitter<StoriesState> emit,
  ) async {
    _streamSubscription ??=
        _preferenceCubit.stream.listen((PreferenceState event) {
      final bool isComplexTile = event.showComplexStoryTile;
      final int pageSize = _getPageSize(isComplexTile: isComplexTile);

      if (pageSize != state.currentPageSize) {
        add(StoriesPageSizeChanged(pageSize: pageSize));
      }
    });
    final bool hasCachedStories = await _cacheRepository.hasCachedStories;
    final bool isComplexTile = _preferenceCubit.state.showComplexStoryTile;
    final int pageSize = _getPageSize(isComplexTile: isComplexTile);
    emit(
      const StoriesState.init().copyWith(
        offlineReading: hasCachedStories,
        currentPageSize: pageSize,
      ),
    );
    await loadStories(of: StoryType.top, emit: emit);
    await loadStories(of: StoryType.latest, emit: emit);
    await loadStories(of: StoryType.ask, emit: emit);
    await loadStories(of: StoryType.show, emit: emit);
    await loadStories(of: StoryType.jobs, emit: emit);
  }

  Future<void> loadStories({
    required StoryType of,
    required Emitter<StoriesState> emit,
  }) async {
    if (state.offlineReading) {
      final List<int> ids = await _cacheRepository.getCachedStoryIds(of: of);
      emit(
        state
            .copyWithStoryIdsUpdated(of: of, to: ids)
            .copyWithCurrentPageUpdated(of: of, to: 0),
      );
      _cacheRepository
          .getCachedStoriesStream(
        ids: ids.sublist(0, min(ids.length, state.currentPageSize)),
      )
          .listen((Story story) {
        add(StoryLoaded(story: story, type: of));
      }).onDone(() {
        add(StoriesLoaded(type: of));
      });
    } else {
      final List<int> ids = await _storiesRepository.fetchStoryIds(of: of);
      emit(
        state
            .copyWithStoryIdsUpdated(of: of, to: ids)
            .copyWithCurrentPageUpdated(of: of, to: 0),
      );
      _storiesRepository
          .fetchStoriesStream(ids: ids.sublist(0, state.currentPageSize))
          .listen((Story story) {
        add(StoryLoaded(story: story, type: of));
      }).onDone(() {
        add(StoriesLoaded(type: of));
      });
    }
  }

  Future<void> onRefresh(
    StoriesRefresh event,
    Emitter<StoriesState> emit,
  ) async {
    emit(
      state.copyWithStatusUpdated(
        of: event.type,
        to: StoriesStatus.loading,
      ),
    );

    if (state.offlineReading) {
      emit(
        state.copyWithStatusUpdated(
          of: event.type,
          to: StoriesStatus.loaded,
        ),
      );
    } else {
      emit(state.copyWithRefreshed(of: event.type));
      await loadStories(of: event.type, emit: emit);
    }
  }

  void onLoadMore(StoriesLoadMore event, Emitter<StoriesState> emit) {
    emit(
      state.copyWithStatusUpdated(
        of: event.type,
        to: StoriesStatus.loading,
      ),
    );

    final int currentPage = state.currentPageByType[event.type]!;
    final int len = state.storyIdsByType[event.type]!.length;
    emit(state.copyWithCurrentPageUpdated(of: event.type, to: currentPage + 1));
    final int currentPageSize = state.currentPageSize;
    final int lower = currentPageSize * (currentPage + 1);
    int upper = currentPageSize + lower;

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
          ),
        )
            .listen((Story story) {
          add(
            StoryLoaded(
              story: story,
              type: event.type,
            ),
          );
        }).onDone(() {
          add(StoriesLoaded(type: event.type));
        });
      } else {
        _storiesRepository
            .fetchStoriesStream(
          ids: state.storyIdsByType[event.type]!.sublist(
            lower,
            upper,
          ),
        )
            .listen((Story story) {
          add(
            StoryLoaded(
              story: story,
              type: event.type,
            ),
          );
        }).onDone(() {
          add(StoriesLoaded(type: event.type));
        });
      }
    } else {
      emit(
        state.copyWithStatusUpdated(
          of: event.type,
          to: StoriesStatus.loaded,
        ),
      );
    }
  }

  Future<void> onStoryLoaded(
    StoryLoaded event,
    Emitter<StoriesState> emit,
  ) async {
    final bool hasRead = await _preferenceRepository.hasRead(event.story.id);
    emit(
      state.copyWithStoryAdded(
        of: event.type,
        story: event.story,
        hasRead: hasRead,
      ),
    );
  }

  void onStoriesLoaded(StoriesLoaded event, Emitter<StoriesState> emit) {
    emit(state.copyWithStatusUpdated(of: event.type, to: StoriesStatus.loaded));
  }

  Future<void> onDownload(
    StoriesDownload event,
    Emitter<StoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        downloadStatus: StoriesDownloadStatus.downloading,
      ),
    );

    await _cacheRepository.deleteAllStoryIds();
    await _cacheRepository.deleteAllStories();
    await _cacheRepository.deleteAllComments();

    final List<int> topIds =
        await _storiesRepository.fetchStoryIds(of: StoryType.top);
    final List<int> newIds =
        await _storiesRepository.fetchStoryIds(of: StoryType.latest);
    final List<int> askIds =
        await _storiesRepository.fetchStoryIds(of: StoryType.ask);
    final List<int> showIds =
        await _storiesRepository.fetchStoryIds(of: StoryType.show);
    final List<int> jobIds =
        await _storiesRepository.fetchStoryIds(of: StoryType.jobs);

    await _cacheRepository.cacheStoryIds(of: StoryType.top, ids: topIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.latest, ids: newIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.ask, ids: askIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.show, ids: showIds);
    await _cacheRepository.cacheStoryIds(of: StoryType.jobs, ids: jobIds);

    final List<int> allIds = <int>[
      ...topIds,
      ...newIds,
      ...askIds,
      ...showIds,
      ...jobIds
    ];

    try {
      _storiesRepository
          .fetchStoriesStream(ids: allIds)
          .listen((Story story) async {
        if (story.kids.isNotEmpty) {
          await _cacheRepository.cacheStory(story: story);
          _storiesRepository
              .fetchAllChildrenComments(ids: story.kids)
              .listen((Comment? comment) async {
            if (comment != null) {
              await _cacheRepository.cacheComment(comment: comment);
            }
          });
        }
      }).onDone(() {
        emit(
          state.copyWith(
            downloadStatus: StoriesDownloadStatus.finished,
          ),
        );
      });
    } catch (_) {
      emit(
        state.copyWith(
          downloadStatus: StoriesDownloadStatus.failure,
        ),
      );
    }
  }

  Future<void> onPageSizeChanged(
    StoriesPageSizeChanged event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesState.init());
    add(StoriesInitialize());
  }

  Future<void> onExitOffline(
    StoriesExitOffline event,
    Emitter<StoriesState> emit,
  ) async {
    await _cacheRepository.deleteAllStoryIds();
    await _cacheRepository.deleteAllStories();
    await _cacheRepository.deleteAllComments();
    emit(state.copyWith(offlineReading: false));
    add(StoriesInitialize());
  }

  Future<void> onStoryRead(
    StoryRead event,
    Emitter<StoriesState> emit,
  ) async {
    unawaited(_preferenceRepository.updateHasRead(event.story.id));

    emit(
      state.copyWith(
        readStoriesIds: <int>{...state.readStoriesIds, event.story.id},
      ),
    );
  }

  Future<void> onClearAllReadStories(
    ClearAllReadStories event,
    Emitter<StoriesState> emit,
  ) async {
    unawaited(_preferenceRepository.clearAllReadStories());

    emit(
      state.copyWith(
        readStoriesIds: <int>{},
      ),
    );
  }

  bool hasRead(Story story) => state.readStoriesIds.contains(story.id);

  int _getPageSize({required bool isComplexTile}) {
    int pageSize = isComplexTile ? _smallPageSize : _largePageSize;

    if (deviceScreenType != DeviceScreenType.mobile) {
      pageSize = isComplexTile ? _tabletSmallPageSize : _tabletLargePageSize;
    }

    return pageSize;
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    await super.close();
  }
}
