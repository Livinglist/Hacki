part of 'stories_bloc.dart';

enum StoriesStatus {
  initial,
  loading,
  loaded,
}

enum StoriesDownloadStatus {
  initial,
  downloading,
  finished,
  failure,
}

class StoriesState extends Equatable {
  const StoriesState({
    required this.storiesByType,
    required this.storyIdsByType,
    required this.statusByType,
    required this.currentPageByType,
    required this.readStoriesIds,
    required this.offlineReading,
    required this.downloadStatus,
    required this.currentPageSize,
    required this.storiesDownloaded,
    required this.storiesToBeDownloaded,
  });

  const StoriesState.init({
    this.storiesByType = const <StoryType, List<Story>>{
      StoryType.top: <Story>[],
      StoryType.best: <Story>[],
      StoryType.latest: <Story>[],
      StoryType.ask: <Story>[],
      StoryType.show: <Story>[],
      StoryType.jobs: <Story>[],
    },
    this.storyIdsByType = const <StoryType, List<int>>{
      StoryType.top: <int>[],
      StoryType.best: <int>[],
      StoryType.latest: <int>[],
      StoryType.ask: <int>[],
      StoryType.show: <int>[],
      StoryType.jobs: <int>[],
    },
    this.statusByType = const <StoryType, StoriesStatus>{
      StoryType.top: StoriesStatus.initial,
      StoryType.best: StoriesStatus.initial,
      StoryType.latest: StoriesStatus.initial,
      StoryType.ask: StoriesStatus.initial,
      StoryType.show: StoriesStatus.initial,
      StoryType.jobs: StoriesStatus.initial,
    },
    this.currentPageByType = const <StoryType, int>{
      StoryType.top: 0,
      StoryType.best: 0,
      StoryType.latest: 0,
      StoryType.ask: 0,
      StoryType.show: 0,
      StoryType.jobs: 0,
    },
  })  : offlineReading = false,
        downloadStatus = StoriesDownloadStatus.initial,
        currentPageSize = 0,
        readStoriesIds = const <int>{},
        storiesDownloaded = 0,
        storiesToBeDownloaded = 0;

  final Map<StoryType, List<Story>> storiesByType;
  final Map<StoryType, List<int>> storyIdsByType;
  final Map<StoryType, StoriesStatus> statusByType;
  final Map<StoryType, int> currentPageByType;
  final Set<int> readStoriesIds;
  final StoriesDownloadStatus downloadStatus;
  final bool offlineReading;
  final int currentPageSize;
  final int storiesDownloaded;
  final int storiesToBeDownloaded;

  StoriesState copyWith({
    Map<StoryType, List<Story>>? storiesByType,
    Map<StoryType, List<int>>? storyIdsByType,
    Map<StoryType, StoriesStatus>? statusByType,
    Map<StoryType, int>? currentPageByType,
    Set<int>? readStoriesIds,
    StoriesDownloadStatus? downloadStatus,
    bool? offlineReading,
    int? currentPageSize,
    int? storiesDownloaded,
    int? storiesToBeDownloaded,
  }) {
    return StoriesState(
      storiesByType: storiesByType ?? this.storiesByType,
      storyIdsByType: storyIdsByType ?? this.storyIdsByType,
      statusByType: statusByType ?? this.statusByType,
      currentPageByType: currentPageByType ?? this.currentPageByType,
      readStoriesIds: readStoriesIds ?? this.readStoriesIds,
      offlineReading: offlineReading ?? this.offlineReading,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      currentPageSize: currentPageSize ?? this.currentPageSize,
      storiesDownloaded: storiesDownloaded ?? this.storiesDownloaded,
      storiesToBeDownloaded:
          storiesToBeDownloaded ?? this.storiesToBeDownloaded,
    );
  }

  StoriesState copyWithStoryAdded({
    required StoryType of,
    required Story story,
    required bool hasRead,
  }) {
    final Map<StoryType, List<Story>> newMap =
        Map<StoryType, List<Story>>.from(storiesByType);
    newMap[of] = List<Story>.from(newMap[of]!)..add(story);
    return copyWith(
      storiesByType: newMap,
      readStoriesIds: <int>{
        ...readStoriesIds,
        if (hasRead) story.id,
      },
    );
  }

  StoriesState copyWithStoryIdsUpdated({
    required StoryType of,
    required List<int> to,
  }) {
    final Map<StoryType, List<int>> newMap =
        Map<StoryType, List<int>>.from(storyIdsByType);
    newMap[of] = to;
    return copyWith(
      storyIdsByType: newMap,
    );
  }

  StoriesState copyWithStatusUpdated({
    required StoryType of,
    required StoriesStatus to,
  }) {
    final Map<StoryType, StoriesStatus> newMap =
        Map<StoryType, StoriesStatus>.from(statusByType);
    newMap[of] = to;
    return copyWith(
      statusByType: newMap,
    );
  }

  StoriesState copyWithCurrentPageUpdated({
    required StoryType of,
    required int to,
  }) {
    final Map<StoryType, int> newMap =
        Map<StoryType, int>.from(currentPageByType);
    newMap[of] = to;
    return copyWith(
      currentPageByType: newMap,
    );
  }

  StoriesState copyWithRefreshed({required StoryType of}) {
    final Map<StoryType, List<Story>> newStoriesMap =
        Map<StoryType, List<Story>>.from(storiesByType);
    newStoriesMap[of] = <Story>[];
    final Map<StoryType, List<int>> newStoryIdsMap =
        Map<StoryType, List<int>>.from(storyIdsByType);
    newStoryIdsMap[of] = <int>[];
    final Map<StoryType, StoriesStatus> newStatusMap =
        Map<StoryType, StoriesStatus>.from(statusByType);
    newStatusMap[of] = StoriesStatus.loading;
    final Map<StoryType, int> newCurrentPageMap =
        Map<StoryType, int>.from(currentPageByType);
    newCurrentPageMap[of] = 0;
    return copyWith(
      storiesByType: newStoriesMap,
      storyIdsByType: newStoryIdsMap,
      statusByType: newStatusMap,
      currentPageByType: newCurrentPageMap,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        storiesByType,
        storyIdsByType,
        statusByType,
        currentPageByType,
        readStoriesIds,
        offlineReading,
        downloadStatus,
        currentPageSize,
        storiesDownloaded,
        storiesToBeDownloaded,
      ];
}
