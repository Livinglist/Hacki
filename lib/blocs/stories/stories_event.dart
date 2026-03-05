part of 'stories_bloc.dart';

abstract class StoriesEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class LoadStories extends StoriesEvent {
  LoadStories({
    required this.type,
    this.isRefreshing = false,
    this.shouldUseApi = false,
  });

  final StoryType type;
  final bool isRefreshing;
  final bool shouldUseApi;

  LoadStories copyWith({required bool shouldUseApi}) {
    return LoadStories(
      type: type,
      isRefreshing: isRefreshing,
      shouldUseApi: shouldUseApi,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        type,
        isRefreshing,
        shouldUseApi,
      ];
}

class StoriesInitialize extends StoriesEvent {
  StoriesInitialize({
    this.startup = false,
  });

  final bool startup;

  @override
  List<Object?> get props => <Object?>[];
}

class StoriesRefresh extends StoriesEvent {
  StoriesRefresh({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => <Object?>[type];
}

class StoriesLoadMore extends StoriesEvent {
  StoriesLoadMore({
    required this.type,
    this.shouldUseApi = false,
  });

  final StoryType type;

  final bool shouldUseApi;

  StoriesLoadMore copyWith({required bool shouldUseApi}) {
    return StoriesLoadMore(type: type, shouldUseApi: shouldUseApi);
  }

  @override
  List<Object?> get props => <Object?>[
        type,
        shouldUseApi,
      ];
}

class StoriesDownload extends StoriesEvent {
  StoriesDownload({required this.includingWebPage});

  final bool includingWebPage;

  @override
  List<Object?> get props => <Object?>[includingWebPage];
}

class StoriesCancelDownload extends StoriesEvent {
  StoriesCancelDownload();

  @override
  List<Object?> get props => <Object?>[];
}

class StoryDownloaded extends StoriesEvent {
  StoryDownloaded({required this.skipped});

  final bool skipped;

  @override
  List<Object?> get props => <Object?>[skipped];
}

class StoriesExitOfflineMode extends StoriesEvent {
  @override
  List<Object?> get props => <Object?>[];
}

class StoriesEnterOfflineMode extends StoriesEvent {
  @override
  List<Object?> get props => <Object?>[];
}

class UpdateMaxOfflineStoriesCount extends StoriesEvent {
  UpdateMaxOfflineStoriesCount({required this.count});

  final MaxOfflineStoriesCount count;

  @override
  List<Object?> get props => <Object?>[count];
}

class ClearMaxOfflineStoriesCount extends StoriesEvent {
  ClearMaxOfflineStoriesCount();

  @override
  List<Object?> get props => <Object?>[];
}

class StoryLoaded extends StoriesEvent {
  StoryLoaded({required this.story, required this.type});

  final Story story;
  final StoryType type;

  @override
  List<Object?> get props => <Object?>[story, type];
}

class StoryLoadingCompleted extends StoryLoaded {
  StoryLoadingCompleted({required super.type}) : super(story: Story.empty());
}

class StoryRead extends StoriesEvent {
  StoryRead({required this.story});

  final Story story;

  @override
  List<Object?> get props => <Object?>[story];
}

class StoryUnread extends StoriesEvent {
  StoryUnread({required this.story});

  final Story story;

  @override
  List<Object?> get props => <Object?>[story];
}

class ClearAllReadStories extends StoriesEvent {
  @override
  List<Object?> get props => <Object?>[];
}
