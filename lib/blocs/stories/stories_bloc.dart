import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:rxdart/rxdart.dart';

part 'stories_event.dart';

part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> with Loggable {
  StoriesBloc({
    required PreferenceCubit preferenceCubit,
    required FilterCubit filterCubit,
    OfflineRepository? offlineRepository,
    HackerNewsRepository? hackerNewsRepository,
    HackerNewsWebRepository? hackerNewsWebRepository,
    PreferenceRepository? preferenceRepository,
  })  : _preferenceCubit = preferenceCubit,
        _filterCubit = filterCubit,
        _offlineRepository =
            offlineRepository ?? locator.get<OfflineRepository>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        _hackerNewsWebRepository =
            hackerNewsWebRepository ?? locator.get<HackerNewsWebRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(const StoriesState.init()) {
    on<LoadStories>(
      onLoadStories,
      transformer: sequential(),
    );
    on<StoriesInitialize>(onInitialize);
    on<StoriesRefresh>(onRefresh);
    on<StoriesLoadMore>(onLoadMore);
    on<StoryLoaded>(
      onStoryLoaded,
      transformer: concurrent(),
    );
    on<StoryRead>(onStoryRead);
    on<StoryUnread>(onStoryUnread);
    on<StoriesDownload>(onDownload);
    on<StoriesCancelDownload>(onCancelDownload);
    on<StoryDownloaded>(onStoryDownloaded);
    on<StoriesEnterOfflineMode>(onEnterOfflineMode);
    on<StoriesExitOfflineMode>(onExitOfflineMode);
    on<ClearAllReadStories>(onClearAllReadStories);

    _preferenceSubscription = _preferenceCubit.stream
        .distinct((PreferenceState lhs, PreferenceState rhs) {
      return lhs.dataSource == rhs.dataSource;
    }).listen((PreferenceState prefState) {
      add(StoriesInitialize());
    });
  }

  final PreferenceCubit _preferenceCubit;
  final FilterCubit _filterCubit;
  final OfflineRepository _offlineRepository;
  final HackerNewsRepository _hackerNewsRepository;
  final HackerNewsWebRepository _hackerNewsWebRepository;
  final PreferenceRepository _preferenceRepository;
  DeviceScreenType? deviceScreenType;
  StreamSubscription<PreferenceState>? _preferenceSubscription;
  static const int apiPageSize = 30;

  Future<void> onInitialize(
    StoriesInitialize event,
    Emitter<StoriesState> emit,
  ) async {
    final HackerNewsDataSource dataSource = _preferenceCubit.state.dataSource;

    emit(
      const StoriesState.init().copyWith(
        downloadStatus: state.downloadStatus,
        storiesDownloaded: state.storiesDownloaded,
        storiesToBeDownloaded: state.storiesToBeDownloaded,
        isOfflineReading: state.isOfflineReading,
        dataSource: dataSource,
      ),
    );

    for (final StoryType type in _preferenceCubit.state.tabs) {
      add(LoadStories(type: type));
    }
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
      final List<int> ids =
          await _offlineRepository.getCachedStoryIds(type: type);
      emit(
        state
            .copyWithStoryIdsUpdated(type: type, to: ids)
            .copyWithCurrentPageUpdated(type: type, to: 0)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );
      _offlineRepository
          .getCachedStoriesStream(ids: ids)
          .listen((Story story) => add(StoryLoaded(story: story, type: type)))
          .onDone(() => add(StoryLoadingCompleted(type: type)));
    } else if (event.useApi || state.dataSource == HackerNewsDataSource.api) {
      final List<int> ids =
          await _hackerNewsRepository.fetchStoryIds(type: type);
      emit(
        state
            .copyWithStoryIdsUpdated(type: type, to: ids)
            .copyWithCurrentPageUpdated(type: type, to: 1)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );

      await _hackerNewsRepository
          .fetchStoriesStream(
        ids: ids.sublist(0, apiPageSize),
        sequential: _preferenceCubit.state.isComplexStoryTileEnabled ||
            _preferenceCubit.state.isFaviconEnabled,
      )
          .listen((Story story) {
        add(StoryLoaded(story: story, type: type));
      }).asFuture<void>();
      add(StoryLoadingCompleted(type: type));
    } else {
      emit(
        state
            .copyWithCurrentPageUpdated(type: type, to: 1)
            .copyWithStatusUpdated(type: type, to: Status.inProgress),
      );

      await _hackerNewsWebRepository
          .fetchStoriesStream(event.type, page: 1)
          .handleError((dynamic e) {
        logError('error loading stories $e');

        switch (e.runtimeType) {
          case RateLimitedException:
          case RateLimitedWithFallbackException:
          case PossibleParsingException:
            add(event.copyWith(useApi: true));
        }
      }).listen((Story story) {
        add(StoryLoaded(story: story, type: type));
      }).asFuture<void>();
      add(StoryLoadingCompleted(type: type));
    }
  }

  Future<void> onRefresh(
    StoriesRefresh event,
    Emitter<StoriesState> emit,
  ) async {
    if (state.statusByType[event.type] == Status.inProgress) return;

    emit(
      state.copyWithStatusUpdated(
        type: event.type,
        to: Status.inProgress,
      ),
    );

    if (state.isOfflineReading) {
      emit(
        state.copyWithStatusUpdated(
          type: event.type,
          to: Status.success,
        ),
      );
    } else {
      emit(state.copyWithRefreshed(type: event.type));
      add(LoadStories(type: event.type, isRefreshing: true));
    }
  }

  Future<void> onLoadMore(
    StoriesLoadMore event,
    Emitter<StoriesState> emit,
  ) async {
    if (state.statusByType[event.type] == Status.inProgress) return;

    emit(
      state.copyWithStatusUpdated(
        type: event.type,
        to: Status.inProgress,
      ),
    );

    final int currentPage = state.currentPageByType[event.type]! + 1;

    emit(
      state.copyWithCurrentPageUpdated(type: event.type, to: currentPage),
    );

    if (state.isOfflineReading) {
      emit(
        state.copyWithStatusUpdated(
          type: event.type,
          to: Status.success,
        ),
      );
    } else if (event.useApi || state.dataSource == HackerNewsDataSource.api) {
      late final int length;
      final List<int>? ids = state.storyIdsByType[event.type];

      if (ids?.isEmpty ?? true) {
        final List<int> ids =
            await _hackerNewsRepository.fetchStoryIds(type: event.type);
        length = ids.length;
        emit(state.copyWith());
      } else {
        length = ids!.length;
      }

      final int lower = min(length, apiPageSize * (currentPage - 1));
      final int upper = min(length, lower + apiPageSize);
      _hackerNewsRepository
          .fetchStoriesStream(
            ids: state.storyIdsByType[event.type]!.sublist(
              lower,
              upper,
            ),
          )
          .listen(
            (Story story) => add(StoryLoaded(story: story, type: event.type)),
          )
          .onDone(() => add(StoryLoadingCompleted(type: event.type)));
    } else {
      _hackerNewsWebRepository
          .fetchStoriesStream(event.type, page: currentPage)
          .handleError((dynamic e) {
            logError('error loading more stories $e');

            switch (e.runtimeType) {
              case RateLimitedException:
              case RateLimitedWithFallbackException:
              case PossibleParsingException:

                /// Fall back to use API instead.
                add(event.copyWith(useApi: true));
                emit(
                  state.copyWithCurrentPageUpdated(
                    type: event.type,
                    to: currentPage - 1,
                  ),
                );
            }
          })
          .listen(
            (Story story) => add(StoryLoaded(story: story, type: event.type)),
          )
          .onDone(() => add(StoryLoadingCompleted(type: event.type)));
    }
  }

  Future<void> onStoryLoaded(
    StoryLoaded event,
    Emitter<StoriesState> emit,
  ) async {
    if (event is StoryLoadingCompleted) {
      emit(
        state.copyWithStatusUpdated(type: event.type, to: Status.success),
      );
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
    final bool hasRead = await _preferenceRepository.hasRead(story.id);
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
    emit(
      state.copyWith(
        downloadStatus: StoriesDownloadStatus.downloading,
      ),
    );

    await _offlineRepository.deleteAllStoryIds();
    await _offlineRepository.deleteAllStories();
    await _offlineRepository.deleteAllComments();
    await _offlineRepository.deleteAllWebPages();

    final Set<int> prioritizedIds = <int>{};

    /// Prioritizing all types of stories except StoryType.latest since
    /// new stories tend to have less or no comment at all.
    final List<StoryType> prioritizedTypes = <StoryType>[...StoryType.values]
      ..remove(StoryType.latest);

    for (final StoryType type in prioritizedTypes) {
      final List<int> ids =
          await _hackerNewsRepository.fetchStoryIds(type: type);
      await _offlineRepository.cacheStoryIds(type: type, ids: ids);
      prioritizedIds.addAll(ids);
    }

    emit(
      state.copyWith(
        storiesDownloaded: 0,
        storiesToBeDownloaded: prioritizedIds.length,
      ),
    );

    try {
      await fetchAndCacheStories(
        prioritizedIds,
        includingWebPage: event.includingWebPage,
        isPrioritized: true,
      );

      final Set<int> latestIds = <int>{};
      final List<int> ids = await _hackerNewsRepository.fetchStoryIds(
        type: StoryType.latest,
      );
      await _offlineRepository.cacheStoryIds(type: StoryType.latest, ids: ids);
      latestIds.addAll(ids);

      await fetchAndCacheStories(
        latestIds,
        includingWebPage: event.includingWebPage,
        isPrioritized: false,
      );
    } catch (_) {
      emit(
        state.copyWith(
          downloadStatus: StoriesDownloadStatus.failure,
        ),
      );
    }
  }

  Future<void> onCancelDownload(
    StoriesCancelDownload event,
    Emitter<StoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        downloadStatus: StoriesDownloadStatus.canceled,
      ),
    );
  }

  Future<void> fetchAndCacheStories(
    Iterable<int> ids, {
    required bool includingWebPage,
    required bool isPrioritized,
  }) async {
    final List<StreamSubscription<Comment>> downloadStreams =
        <StreamSubscription<Comment>>[];
    for (final int id in ids) {
      if (state.downloadStatus == StoriesDownloadStatus.canceled) {
        logDebug('aborting downloading');

        for (final StreamSubscription<Comment> stream in downloadStreams) {
          await stream.cancel();
        }

        logDebug('deleting downloaded contents');
        await _offlineRepository.deleteAllStoryIds();
        await _offlineRepository.deleteAllStories();
        await _offlineRepository.deleteAllComments();
        break;
      }

      logDebug('fetching story $id');
      final Story? story = await _hackerNewsRepository.fetchStory(id: id);

      if (story == null) {
        if (isPrioritized) {
          add(StoryDownloaded(skipped: true));
        }
        continue;
      }

      if (story.kids.isEmpty) {
        if (isPrioritized) {
          add(StoryDownloaded(skipped: true));
        }
        continue;
      }

      await _offlineRepository.cacheStory(story: story);

      if (story.url.isNotEmpty && includingWebPage) {
        logInfo('downloading ${story.url}');
        await _offlineRepository.cacheUrl(url: story.url);
      }

      /// Not awaiting the completion of comments stream because otherwise
      /// it's going to take forever to finish downloading all the stories
      /// since we need to make a single http call for each comment.
      ///
      /// In other words, we are prioritizing the story itself instead of
      /// the comments in the story.
      late final StreamSubscription<Comment>? downloadStream;
      downloadStream = _hackerNewsRepository
          .fetchAllChildrenComments(ids: story.kids)
          .whereType<Comment>()
          .listen(
        (Comment comment) {
          if (state.downloadStatus == StoriesDownloadStatus.canceled) {
            logDebug('aborting downloading from comments stream');
            downloadStream?.cancel();
            return;
          }

          logDebug('fetched comment ${comment.id}');
          unawaited(
            _offlineRepository.cacheComment(comment: comment),
          );
        },
      )..onDone(() {
          logDebug(
            '''finished downloading story ${story.id} with ${story.descendants} comments''',
          );
          add(StoryDownloaded(skipped: false));
        });

      downloadStreams.add(downloadStream);
    }
  }

  void onStoryDownloaded(StoryDownloaded event, Emitter<StoriesState> emit) {
    if (event.skipped) {
      final int updatedStoriesToBeDownloaded = state.storiesToBeDownloaded - 1;

      emit(
        state.copyWith(
          storiesToBeDownloaded: updatedStoriesToBeDownloaded,
          downloadStatus:
              state.storiesDownloaded == updatedStoriesToBeDownloaded
                  ? StoriesDownloadStatus.finished
                  : null,
        ),
      );
    } else {
      final int updatedStoriesDownloaded = state.storiesDownloaded + 1;
      final int updatedStoriesToBeDownloaded =
          updatedStoriesDownloaded > state.storiesToBeDownloaded
              ? state.storiesToBeDownloaded + 1
              : state.storiesToBeDownloaded;

      emit(
        state.copyWith(
          storiesDownloaded: updatedStoriesDownloaded,
          storiesToBeDownloaded: updatedStoriesToBeDownloaded,
          downloadStatus:
              updatedStoriesDownloaded == updatedStoriesToBeDownloaded
                  ? StoriesDownloadStatus.finished
                  : null,
        ),
      );
    }
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

  Future<void> onStoryRead(
    StoryRead event,
    Emitter<StoriesState> emit,
  ) async {
    unawaited(_preferenceRepository.addHasRead(event.story.id));

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
    unawaited(_preferenceRepository.removeHasRead(event.story.id));

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
    unawaited(_preferenceRepository.clearAllReadStories());

    emit(
      state.copyWith(
        readStoriesIds: <int>{},
      ),
    );
  }

  bool hasRead(Story story) => state.readStoriesIds.contains(story.id);

  @override
  Future<void> close() async {
    await _preferenceSubscription?.cancel();
    await super.close();
  }

  @override
  String get logIdentifier => '[StoriesBloc]';
}
