part of 'stories_bloc.dart';

abstract class StoriesEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class StoriesInitialize extends StoriesEvent {
  @override
  List<Object?> get props => <Object?>[];
}

class StoriesLoaded extends StoriesEvent {
  StoriesLoaded({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => <Object?>[type];
}

class StoriesRefresh extends StoriesEvent {
  StoriesRefresh({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => <Object?>[type];
}

class StoriesLoadMore extends StoriesEvent {
  StoriesLoadMore({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => <Object?>[type];
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

class StoriesExitOffline extends StoriesEvent {
  @override
  List<Object?> get props => <Object?>[];
}

class StoriesPageSizeChanged extends StoriesEvent {
  StoriesPageSizeChanged({required this.pageSize});

  final int pageSize;

  @override
  List<Object?> get props => <Object?>[pageSize];
}

class StoryLoaded extends StoriesEvent {
  StoryLoaded({required this.story, required this.type});

  final Story story;
  final StoryType type;

  @override
  List<Object?> get props => <Object?>[story, type];
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
