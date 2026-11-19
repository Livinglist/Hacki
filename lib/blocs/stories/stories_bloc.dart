import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';

part 'stories_event.dart';

part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> with Loggable {
  StoriesBloc({
    required PreferenceCubit preferenceCubit,
    required FilterCubit filterCubit,
    required HideCubit hideCubit,
    OfflineRepository? offlineRepository,
    HackerNewsRepository? hackerNewsRepository,
    HackerNewsWebRepository? hackerNewsWebRepository,
    HistoryRepository? historyRepository,
    PreferenceRepository? preferenceRepository,
  }) : _preferenceCubit = preferenceCubit,
       _filterCubit = filterCubit,
       _hideCubit = hideCubit,
       _offlineRepository =
           offlineRepository ?? locator.get<OfflineRepository>(),
       _hackerNewsRepository =
           hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
       _hackerNewsWebRepository =
           hackerNewsWebRepository ?? locator.get<HackerNewsWebRepository>(),
       _historyRepository =
           historyRepository ?? locator.get<HistoryRepository>(),
       _preferenceRepository =
           preferenceRepository ?? locator.get<PreferenceRepository>(),
       super(const StoriesState.init()) {
    on<LoadStories>(onLoadStories, transformer: concurrent());
    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(onStoryLoaded, transformer: sequential());
    on<StoryRead>(onStoryRead);
    on<StoryUnread>(onStoryUnread);
    on<StoriesDownload>(onDownload);
    on<StoriesCancelDownload>(onCancelDownload);
    on<StoriesEnterOfflineMode>(onEnterOfflineMode);
    on<StoriesExitOfflineMode>(onExitOfflineMode);
    on<ClearAllReadStories>(onClearAllReadStories);
    on<UpdateMaxOfflineStoriesCount>(onUpdateMaxOfflineStoriesCount);
    on<ClearMaxOfflineStoriesCount>(onClearMaxOfflineStoriesCount);

    _preferenceStatusSubscription ??= _preferenceCubit.stream
        .map((PreferenceState s) => s.status)
        .distinct()
        .listen((Status status) {
          if (status.isSuccessful) {
            add(StoriesInitialize(startup: true));
            _preferenceStatusSubscription?.cancel();
          }
        });
  }

  final PreferenceCubit _preferenceCubit;
  final FilterCubit _filterCubit;
  final HideCubit _hideCubit;
  final OfflineRepository _offlineRepository;
  final HackerNewsRepository _hackerNewsRepository;
  final HackerNewsWebRepository _hackerNewsWebRepository;
  final HistoryRepository _historyRepository;
  final PreferenceRepository _preferenceRepository;
  DeviceScreenType? deviceScreenType;
  StreamSubscription<PreferenceState>? _preferenceSubscription;
  StreamSubscription<Status>? _preferenceStatusSubscription;
  final Map<StoryType, StreamSubscription<Story>> _storySubscriptions =
      <StoryType, StreamSubscription<Story>>{};
  _StoriesDownloadRun? _download;
  bool _closing = false;

  static const int _pageSize = 30;
  static const int _downloadConcurrency = 4;

  Future<void> onInitialize(
    StoriesInitialize event,
    Emitter<StoriesState> emit,
  ) async {
    final HackerNewsDataSource dataSource = _preferenceCubit.state.dataSource;
    logInfo('initializing stories from data source: $dataSource');
    logInfo('is starting up? ${event.startup}');

    for (final StreamSubscription<Story> s in _storySubscriptions.values) {
      await s.cancel();
    }

    final int? downloadTimestamp = await _getDownloadTimestamp();

    emit(
      const StoriesState.init().copyWith(
        downloadStatus: state.downloadStatus,
        storiesDownloaded: state.storiesDownloaded,
        storiesToBeDownloaded: state.storiesToBeDownloaded,
        isOfflineReading: state.isOfflineReading,
        dataSource: dataSource,
        downloadTimestamp: downloadTimestamp,
      ),
    );

    if (event.startup) {
      final List<ConnectivityResult> status = await Connectivity()
          .checkConnectivity();
      logInfo('network status: $status');
      if (status.contains(ConnectivityResult.none)) {
        logInfo('no network connection, entering offline mode.');
        add(StoriesEnterOfflineMode());
      }
    }

    for (final StoryType type in _preferenceCubit.state.tabs) {
      add(LoadStories(type: type));
    }

    _preferenceSubscription ??= _preferenceCubit.stream
        .distinct((PreferenceState lhs, PreferenceState rhs) {
          return lhs.dataSource == rhs.dataSource;
        })
        .listen((PreferenceState prefState) {
          add(StoriesInitialize());
        });
  }

  Future<void> onLoadStories(
    LoadStories event,
    Emitter<StoriesState> emit,
  ) async {
    if (state.dataSource == null) {
      logError('data source should not be null.');
    }

    final StoryType type = event.type;
    if (state.isOfflineReading) {
      logInfo('($type) loading stories from local cache.');
      final List<int> ids = await _offlineRepository.getCachedStoryIds(
        type: type,
      );
      emit(
        state
            .copyWithStoryIdsUpdated(type: type, to: ids)
            .copyWithCurrentPageUpdated(type: type, to: 1)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );
      _offlineRepository
          .getCachedStoriesStream(
            ids: ids.sublist(0, min(_pageSize, ids.length)),
          )
          .listen((Story story) => add(StoryLoaded(story: story, type: type)))
          .onDone(() => add(StoryLoadingCompleted(type: type)));
    } else if (event.shouldUseApi ||
        state.dataSource == HackerNewsDataSource.api) {
      logInfo('($type) loading stories from API.');
      final List<int> ids = await _hackerNewsRepository.fetchStoryIds(
        type: type,
      );

      if (_preferenceCubit.state.isHideInsteadOfMarkingGrayEnabled) {
        ids.removeWhere(_hideCubit.isHidden);
      }

      emit(
        state
            .copyWithStoryIdsUpdated(type: type, to: ids)
            .copyWithCurrentPageUpdated(type: type, to: 1)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );

      await _storySubscriptions[type]?.cancel();
      _storySubscriptions[type] =
          _hackerNewsRepository
              .fetchStoriesStream(
                ids: ids.sublist(0, min(_pageSize, ids.length)),
                sequential: true,
              )
              .listen(
                (Story story) => add(StoryLoaded(story: story, type: type)),
              )
            ..onDone(() => add(StoryLoadingCompleted(type: type)));
    } else {
      logInfo('($type) loading stories from web.');
      emit(
        state
            .copyWithCurrentPageUpdated(type: type, to: 1)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );

      await _storySubscriptions[type]?.cancel();
      _storySubscriptions[type] =
          _hackerNewsWebRepository
              .fetchStoriesStream(event.type, page: 1)
              .handleError((dynamic e) {
                logError('($type) error loading stories from web $e');

                switch (e.runtimeType) {
                  case RateLimitedException:
                  case RateLimitedWithFallbackException:
                  case ParsingException:
                    add(event.copyWith(shouldUseApi: true));
                }
              })
              .listen((Story story) {
                if (_hideCubit.isHidden(story.id)) {
                  return;
                } else {
                  add(StoryLoaded(story: story, type: type));
                }
              })
            ..onDone(() => add(StoryLoadingCompleted(type: type)));
    }
  }

  Future<void> onRefresh(
    StoriesRefresh event,
    Emitter<StoriesState> emit,
  ) async {
    if (state.statusByType[event.type] == Status.inProgress) return;

    emit(state.copyWithStatusUpdated(type: event.type, to: Status.inProgress));

    if (state.isOfflineReading) {
      emit(state.copyWithStatusUpdated(type: event.type, to: Status.success));
    } else {
      emit(state.copyWithRefreshed(type: event.type));
      add(LoadStories(type: event.type, isRefreshing: true));
    }
  }

  Future<void> onLoadMore(
    StoriesLoadMore event,
    Emitter<StoriesState> emit,
  ) async {
    final StoryType type = event.type;

    if (state.statusByType[type] == Status.inProgress) return;

    emit(state.copyWithStatusUpdated(type: type, to: Status.inProgress));

    final int currentPage = state.currentPageByType[type]! + 1;

    emit(state.copyWithCurrentPageUpdated(type: type, to: currentPage));

    if (state.isOfflineReading) {
      final List<int>? ids = state.storyIdsByType[type];
      if (ids == null) {
        logError('ids should not be null.');
        emit(state.copyWithStatusUpdated(type: type, to: Status.failure));
        return;
      }
      final int length = ids.length;
      final int lower = min(length, _pageSize * (currentPage - 1));
      final int upper = min(length, lower + _pageSize);
      final List<int> idsForCurrentPage = ids.sublist(lower, upper);
      _offlineRepository
          .getCachedStoriesStream(ids: idsForCurrentPage)
          .listen((Story story) => add(StoryLoaded(story: story, type: type)))
          .onDone(() => add(StoryLoadingCompleted(type: type)));
    } else if (event.shouldUseApi ||
        state.dataSource == HackerNewsDataSource.api) {
      late final int length;
      List<int>? ids = state.storyIdsByType[type];

      if (ids == null || ids.isEmpty) {
        ids = await _hackerNewsRepository.fetchStoryIds(type: type);
        length = ids.length;
        emit(state.copyWithStoryIdsUpdated(type: type, to: ids));
      } else {
        length = ids.length;
      }

      final int lower = min(length, _pageSize * (currentPage - 1));
      final int upper = min(length, lower + _pageSize);
      final List<int> idsForCurrentPage = ids.sublist(lower, upper);
      _hackerNewsRepository
          .fetchStoriesStream(ids: idsForCurrentPage)
          .listen((Story story) => add(StoryLoaded(story: story, type: type)))
          .onDone(() => add(StoryLoadingCompleted(type: type)));
    } else {
      _hackerNewsWebRepository
          .fetchStoriesStream(type, page: currentPage)
          .handleError((dynamic e) {
            logError('error loading more stories $e');

            switch (e.runtimeType) {
              case RateLimitedException:
              case RateLimitedWithFallbackException:
              case ParsingException:

                /// Fall back to use API instead.
                add(event.copyWith(shouldUseApi: true));
                emit(
                  state.copyWithCurrentPageUpdated(
                    type: type,
                    to: currentPage - 1,
                  ),
                );
            }
          })
          .listen((Story story) {
            if (_hideCubit.isHidden(story.id)) {
              return;
            } else {
              add(StoryLoaded(story: story, type: type));
            }
          })
          .onDone(() => add(StoryLoadingCompleted(type: type)));
    }
  }

  Future<void> onStoryLoaded(
    StoryLoaded event,
    Emitter<StoriesState> emit,
  ) async {
    if (event is StoryLoadingCompleted) {
      logInfo('loading of ${event.type} stories completed.');
      emit(state.copyWithStatusUpdated(type: event.type, to: Status.success));
      return;
    }

    final Story story = event.story;
    if (state.storiesByType[event.type]
            ?.where((Story s) => s.id == story.id)
            .isNotEmpty ??
        false) {
      logDebug('story ${story.id} for ${event.type} already exists.');
      return;
    }
    final bool hasRead = await _historyRepository.hasRead(story.id);
    final bool hidden = _filterCubit.state.keywords.any((String keyword) {
      // Match word only.
      final RegExp regExp = RegExp('\\b($keyword)\\b');
      return regExp.hasMatch(story.title.toLowerCase()) ||
          regExp.hasMatch(story.text.toLowerCase());
    });

    emit(
      state.copyWithStoryAdded(
        type: event.type,
        story: story.copyWith(hidden: hidden),
        hasRead: hasRead,
      ),
    );
  }

  Future<void> onDownload(
    StoriesDownload event,
    Emitter<StoriesState> emit,
  ) async {
    final _StoriesDownloadRun? previous = _download;
    if (previous != null) {
      if (!previous.canceled) return;
      // A replacement must not clear the cache while old writes are pending.
      await previous.done.future;
    }
    if (_closing || emit.isDone || _download != null) return;

    final _StoriesDownloadRun run = _StoriesDownloadRun();
    final int? limit = state.maxOfflineStoriesCount?.count;
    _download = run;
    emit(
      state.copyWith(
        downloadStatus: StoriesDownloadStatus.downloading,
        storiesDownloaded: 0,
        storiesToBeDownloaded: 0,
      ),
    );

    try {
      await _clearOfflineDownload();
      if (run.stopped || emit.isDone) return;

      // Keep latest last, but deduplicate it against the prioritized feeds.
      final Set<int> ids = <int>{};
      for (final StoryType type in <StoryType>[
        StoryType.top,
        StoryType.best,
        StoryType.ask,
        StoryType.show,
        StoryType.latest,
      ]) {
        final List<int> feedIds = await _hackerNewsRepository.fetchStoryIds(
          type: type,
        );
        if (run.stopped || emit.isDone) return;
        await _offlineRepository.cacheStoryIds(type: type, ids: feedIds);
        if (run.stopped || emit.isDone) return;
        ids.addAll(feedIds);
      }

      final List<int> selectedIds = ids.take(limit ?? ids.length).toList();
      emit(state.copyWith(storiesToBeDownloaded: selectedIds.length));
      await _downloadStories(
        selectedIds,
        includingWebPage: event.includingWebPage,
        run: run,
        emit: emit,
      );
      if (run.stopped || emit.isDone) return;

      // All content is written. Commit success once, instead of deriving it
      // from progress counters or individual stream callbacks.
      run.completing = true;
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      await _saveDownloadTimestamp(timestamp);
      if (run.stopped || emit.isDone) return;
      emit(
        state.copyWith(
          downloadStatus: StoriesDownloadStatus.finished,
          downloadTimestamp: timestamp,
        ),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace: stackTrace);
      run.stopped = true;
      if (!run.canceled && !emit.isDone) {
        emit(state.copyWith(downloadStatus: StoriesDownloadStatus.failure));
      }
    } finally {
      try {
        if (run.canceled) {
          await _clearOfflineDownload();
          if (!emit.isDone) {
            emit(
              state.copyWith(
                downloadStatus: StoriesDownloadStatus.canceled,
                storiesDownloaded: 0,
                storiesToBeDownloaded: 0,
              ),
            );
          }
        }
      } catch (error, stackTrace) {
        logError(error, stackTrace: stackTrace);
        if (!emit.isDone) {
          emit(state.copyWith(downloadStatus: StoriesDownloadStatus.failure));
        }
      } finally {
        _download = null;
        run.done.complete();
      }
    }
  }

  Future<void> onCancelDownload(
    StoriesCancelDownload event,
    Emitter<StoriesState> emit,
  ) async {
    final _StoriesDownloadRun? run = _download;
    if (run == null || run.completing) return;
    run
      ..canceled = true
      ..stopped = true;
    await _cancelDownloadStreams(run);
    await run.done.future;
  }

  Future<void> _downloadStories(
    List<int> ids, {
    required bool includingWebPage,
    required _StoriesDownloadRun run,
    required Emitter<StoriesState> emit,
  }) async {
    int nextIndex = 0;
    Future<void> downloadNext() async {
      try {
        while (!run.stopped && !emit.isDone && nextIndex < ids.length) {
          final int id = ids[nextIndex++];
          final Story? story = await _hackerNewsRepository.fetchStory(id: id);
          if (run.stopped || emit.isDone) return;

          if (story == null || story.kids.isEmpty) {
            emit(
              state.copyWith(
                storiesToBeDownloaded: state.storiesToBeDownloaded - 1,
              ),
            );
            continue;
          }

          await _offlineRepository.cacheStory(story: story);
          if (run.stopped || emit.isDone) return;
          if (story.url.isNotEmpty && includingWebPage) {
            await _offlineRepository.cacheUrl(url: story.url);
            if (run.stopped || emit.isDone) return;
          }

          final StreamIterator<Comment?> comments = StreamIterator<Comment?>(
            _hackerNewsRepository.fetchAllChildrenComments(ids: story.kids),
          );
          run.comments.add(comments);
          try {
            while (await comments.moveNext()) {
              if (run.stopped || emit.isDone) return;
              final Comment? comment = comments.current;
              if (comment != null) {
                await _offlineRepository.cacheComment(comment: comment);
              }
              if (run.stopped || emit.isDone) return;
            }
          } finally {
            run.comments.remove(comments);
            await comments.cancel();
          }
          if (run.stopped || emit.isDone) return;
          emit(state.copyWith(storiesDownloaded: state.storiesDownloaded + 1));
        }
      } catch (_) {
        run.stopped = true;
        await _cancelDownloadStreams(run);
        rethrow;
      }
    }

    // Future.wait also waits for the other workers on failure, so no write
    // from this run can race with a retry clearing or replacing the cache.
    await Future.wait<void>(<Future<void>>[
      for (int i = 0; i < min(_downloadConcurrency, ids.length); i++)
        downloadNext(),
    ]);
  }

  Future<void> _cancelDownloadStreams(_StoriesDownloadRun run) async {
    await Future.wait<void>(
      run.comments.toList().map(
        (StreamIterator<Comment?> comments) => comments.cancel(),
      ),
    );
  }

  Future<void> _clearOfflineDownload() async {
    await _offlineRepository.deleteAllStoryIds();
    await _offlineRepository.deleteAllStories();
    await _offlineRepository.deleteAllComments();
    await _offlineRepository.deleteAllWebPages();
  }

  Future<void> onExitOfflineMode(
    StoriesExitOfflineMode event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(isOfflineReading: false));
    add(StoriesInitialize());
  }

  Future<void> onEnterOfflineMode(
    StoriesEnterOfflineMode event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(isOfflineReading: true));
    add(StoriesInitialize());
  }

  Future<void> onUpdateMaxOfflineStoriesCount(
    UpdateMaxOfflineStoriesCount event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(maxOfflineStoriesCount: event.count));
  }

  Future<void> onClearMaxOfflineStoriesCount(
    ClearMaxOfflineStoriesCount event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWithMaxOfflineStoriesCountReset());
  }

  Future<void> onStoryRead(StoryRead event, Emitter<StoriesState> emit) async {
    unawaited(_historyRepository.saveReadStoryId(event.story.id));

    emit(
      state.copyWith(
        readStoriesIds: <int>{...state.readStoriesIds, event.story.id},
      ),
    );
  }

  Future<void> onStoryUnread(
    StoryUnread event,
    Emitter<StoriesState> emit,
  ) async {
    unawaited(_historyRepository.removeReadStoryId(event.story.id));

    emit(
      state.copyWith(
        readStoriesIds: <int>{...state.readStoriesIds}..remove(event.story.id),
      ),
    );
  }

  Future<void> onClearAllReadStories(
    ClearAllReadStories event,
    Emitter<StoriesState> emit,
  ) async {
    unawaited(_historyRepository.clearAllReadStoryIds());

    emit(state.copyWith(readStoriesIds: <int>{}));
  }

  bool hasRead(Story story) => state.readStoriesIds.contains(story.id);

  @override
  Future<void> close() async {
    _closing = true;
    final _StoriesDownloadRun? run = _download;
    if (run != null) {
      run.stopped = true;
      await _cancelDownloadStreams(run);
      await run.done.future;
    }
    await _preferenceStatusSubscription?.cancel();
    await _preferenceSubscription?.cancel();
    for (final StreamSubscription<Story> s in _storySubscriptions.values) {
      await s.cancel();
    }
    await super.close();
  }

  @override
  String get logIdentifier => 'StoriesBloc';
}

class _StoriesDownloadRun {
  final Completer<void> done = Completer<void>();
  final Set<StreamIterator<Comment?>> comments = <StreamIterator<Comment?>>{};
  bool stopped = false;
  bool canceled = false;
  bool completing = false;
}

extension on StoriesBloc {
  Future<void> _saveDownloadTimestamp(int timestamp) async {
    await _preferenceRepository.setDownloadTimestamp(timestamp: timestamp);
  }

  Future<int?> _getDownloadTimestamp() async {
    final int? timestamp = await _preferenceRepository.getDownloadTimestamp();
    return timestamp;
  }
}
