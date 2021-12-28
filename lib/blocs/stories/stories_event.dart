part of 'stories_bloc.dart';

abstract class StoriesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StoriesInitialize extends StoriesEvent {
  @override
  List<Object?> get props => [];
}

class StoriesLoaded extends StoriesEvent {
  StoriesLoaded({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => [type];
}

class StoriesRefresh extends StoriesEvent {
  StoriesRefresh({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => [type];
}

class StoriesLoadMore extends StoriesEvent {
  StoriesLoadMore({required this.type});

  final StoryType type;

  @override
  List<Object?> get props => [type];
}

class StoryLoaded extends StoriesEvent {
  StoryLoaded({required this.story, required this.type});

  final Story story;
  final StoryType type;

  @override
  List<Object?> get props => [story, type];
}
