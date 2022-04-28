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
    required this.offlineReading,
    required this.downloadStatus,
    required this.currentPageSize,
  });

  const StoriesState.init({
    this.storiesByType = const <StoryType, List<Story>>{
      StoryType.top: <Story>[],
      StoryType.latest: <Story>[],
      StoryType.ask: <Story>[],
      StoryType.show: <Story>[],
      StoryType.jobs: <Story>[],
    },
    this.storyIdsByType = const <StoryType, List<int>>{
      StoryType.top: <int>[],
      StoryType.latest: <int>[],
      StoryType.ask: <int>[],
      StoryType.show: <int>[],
      StoryType.jobs: <int>[],
    },
    this.statusByType = const <StoryType, StoriesStatus>{
      StoryType.top: StoriesStatus.initial,
      StoryType.latest: StoriesStatus.initial,
      StoryType.ask: StoriesStatus.initial,
      StoryType.show: StoriesStatus.initial,
      StoryType.jobs: StoriesStatus.initial,
    },
    this.currentPageByType = const <StoryType, int>{
      StoryType.top: 0,
      StoryType.latest: 0,
      StoryType.ask: 0,
      StoryType.show: 0,
      StoryType.jobs: 0,
    },
  })  : offlineReading = false,
        downloadStatus = StoriesDownloadStatus.initial,
        currentPageSize = 0;

  final Map<StoryType, List<Story>> storiesByType;
  final Map<StoryType, List<int>> storyIdsByType;
  final Map<StoryType, StoriesStatus> statusByType;
  final Map<StoryType, int> currentPageByType;
  final StoriesDownloadStatus downloadStatus;
  final bool offlineReading;
  final int currentPageSize;

  StoriesState copyWith({
    Map<StoryType, List<Story>>? storiesByType,
    Map<StoryType, List<int>>? storyIdsByType,
    Map<StoryType, StoriesStatus>? statusByType,
    Map<StoryType, int>? currentPageByType,
    StoriesDownloadStatus? downloadStatus,
    bool? offlineReading,
    int? currentPageSize,
  }) {
    return StoriesState(
      storiesByType: storiesByType ?? this.storiesByType,
      storyIdsByType: storyIdsByType ?? this.storyIdsByType,
      statusByType: statusByType ?? this.statusByType,
      currentPageByType: currentPageByType ?? this.currentPageByType,
      offlineReading: offlineReading ?? this.offlineReading,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      currentPageSize: currentPageSize ?? this.currentPageSize,
    );
  }

  StoriesState copyWithStoryAdded({
    required StoryType of,
    required Story story,
  }) {
    final Map<StoryType, List<Story>> newMap =
        Map<StoryType, List<Story>>.from(storiesByType);
    newMap[of] = List<Story>.from(newMap[of]!)..add(story);
    return StoriesState(
      storiesByType: newMap,
      storyIdsByType: storyIdsByType,
      statusByType: statusByType,
      currentPageByType: currentPageByType,
      offlineReading: offlineReading,
      downloadStatus: downloadStatus,
      currentPageSize: currentPageSize,
    );
  }

  StoriesState copyWithStoryIdsUpdated({
    required StoryType of,
    required List<int> to,
  }) {
    final Map<StoryType, List<int>> newMap =
        Map<StoryType, List<int>>.from(storyIdsByType);
    newMap[of] = to;
    return StoriesState(
      storiesByType: storiesByType,
      storyIdsByType: newMap,
      statusByType: statusByType,
      currentPageByType: currentPageByType,
      offlineReading: offlineReading,
      downloadStatus: downloadStatus,
      currentPageSize: currentPageSize,
    );
  }

  StoriesState copyWithStatusUpdated({
    required StoryType of,
    required StoriesStatus to,
  }) {
    final Map<StoryType, StoriesStatus> newMap =
        Map<StoryType, StoriesStatus>.from(statusByType);
    newMap[of] = to;
    return StoriesState(
      storiesByType: storiesByType,
      storyIdsByType: storyIdsByType,
      statusByType: newMap,
      currentPageByType: currentPageByType,
      offlineReading: offlineReading,
      downloadStatus: downloadStatus,
      currentPageSize: currentPageSize,
    );
  }

  StoriesState copyWithCurrentPageUpdated({
    required StoryType of,
    required int to,
  }) {
    final Map<StoryType, int> newMap =
        Map<StoryType, int>.from(currentPageByType);
    newMap[of] = to;
    return StoriesState(
      storiesByType: storiesByType,
      storyIdsByType: storyIdsByType,
      statusByType: statusByType,
      currentPageByType: newMap,
      offlineReading: offlineReading,
      downloadStatus: downloadStatus,
      currentPageSize: currentPageSize,
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
    return StoriesState(
      storiesByType: newStoriesMap,
      storyIdsByType: newStoryIdsMap,
      statusByType: newStatusMap,
      currentPageByType: newCurrentPageMap,
      offlineReading: offlineReading,
      downloadStatus: downloadStatus,
      currentPageSize: currentPageSize,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        storiesByType,
        storyIdsByType,
        statusByType,
        currentPageByType,
        offlineReading,
        downloadStatus,
        currentPageSize,
      ];
}
