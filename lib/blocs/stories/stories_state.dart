part of 'stories_bloc.dart';

enum StoriesDownloadStatus {
  idle,
  downloading,
  finished,
  failure,
  canceled,
}

class StoriesState extends Equatable {
  const StoriesState({
    required this.storiesByType,
    required this.storyIdsByType,
    required this.statusByType,
    required this.currentPageByType,
    required this.readStoriesIds,
    required this.isOfflineReading,
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
    },
    this.storyIdsByType = const <StoryType, List<int>>{
      StoryType.top: <int>[],
      StoryType.best: <int>[],
      StoryType.latest: <int>[],
      StoryType.ask: <int>[],
      StoryType.show: <int>[],
    },
    this.statusByType = const <StoryType, Status>{
      StoryType.top: Status.idle,
      StoryType.best: Status.idle,
      StoryType.latest: Status.idle,
      StoryType.ask: Status.idle,
      StoryType.show: Status.idle,
    },
    this.currentPageByType = const <StoryType, int>{
      StoryType.top: 0,
      StoryType.best: 0,
      StoryType.latest: 0,
      StoryType.ask: 0,
      StoryType.show: 0,
    },
  })  : isOfflineReading = false,
        downloadStatus = StoriesDownloadStatus.idle,
        currentPageSize = 0,
        readStoriesIds = const <int>{},
        storiesDownloaded = 0,
        storiesToBeDownloaded = 0;

  final Map<StoryType, List<Story>> storiesByType;
  final Map<StoryType, List<int>> storyIdsByType;
  final Map<StoryType, Status> statusByType;
  final Map<StoryType, int> currentPageByType;
  final Set<int> readStoriesIds;
  final StoriesDownloadStatus downloadStatus;
  final bool isOfflineReading;
  final int currentPageSize;
  final int storiesDownloaded;
  final int storiesToBeDownloaded;

  StoriesState copyWith({
    Map<StoryType, List<Story>>? storiesByType,
    Map<StoryType, List<int>>? storyIdsByType,
    Map<StoryType, Status>? statusByType,
    Map<StoryType, int>? currentPageByType,
    Set<int>? readStoriesIds,
    StoriesDownloadStatus? downloadStatus,
    bool? isOfflineReading,
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
      isOfflineReading: isOfflineReading ?? this.isOfflineReading,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      currentPageSize: currentPageSize ?? this.currentPageSize,
      storiesDownloaded: storiesDownloaded ?? this.storiesDownloaded,
      storiesToBeDownloaded:
          storiesToBeDownloaded ?? this.storiesToBeDownloaded,
    );
  }

  StoriesState copyWithStoryAdded({
    required StoryType type,
    required Story story,
    required bool hasRead,
  }) {
    final Map<StoryType, List<Story>> newMap =
        Map<StoryType, List<Story>>.from(storiesByType);
    newMap[type] = List<Story>.from(newMap[type]!)..add(story);
    return copyWith(
      storiesByType: newMap,
      readStoriesIds: <int>{
        ...readStoriesIds,
        if (hasRead) story.id,
      },
    );
  }

  StoriesState copyWithStoryIdsUpdated({
    required StoryType type,
    required List<int> to,
  }) {
    final Map<StoryType, List<int>> newMap =
        Map<StoryType, List<int>>.from(storyIdsByType);
    newMap[type] = to;
    return copyWith(
      storyIdsByType: newMap,
    );
  }

  StoriesState copyWithStatusUpdated({
    required StoryType type,
    required Status to,
  }) {
    final Map<StoryType, Status> newMap =
        Map<StoryType, Status>.from(statusByType);
    newMap[type] = to;
    return copyWith(
      statusByType: newMap,
    );
  }

  StoriesState copyWithCurrentPageUpdated({
    required StoryType type,
    required int to,
  }) {
    final Map<StoryType, int> newMap =
        Map<StoryType, int>.from(currentPageByType);
    newMap[type] = to;
    return copyWith(
      currentPageByType: newMap,
    );
  }

  StoriesState copyWithRefreshed({required StoryType type}) {
    final Map<StoryType, Status> newStatusMap =
        Map<StoryType, Status>.from(statusByType);
    newStatusMap[type] = Status.inProgress;
    final Map<StoryType, int> newCurrentPageMap =
        Map<StoryType, int>.from(currentPageByType);
    newCurrentPageMap[type] = 0;
    return copyWith(
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
        isOfflineReading,
        downloadStatus,
        currentPageSize,
        storiesDownloaded,
        storiesToBeDownloaded,
      ];
}
