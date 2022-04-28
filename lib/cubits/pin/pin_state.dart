part of 'pin_cubit.dart';

class PinState extends Equatable {
  const PinState({
    required this.pinnedStoriesIds,
    required this.pinnedStories,
  });

  PinState.init()
      : pinnedStoriesIds = <int>[],
        pinnedStories = <Story>[];

  final List<int> pinnedStoriesIds;
  final List<Story> pinnedStories;

  PinState copyWith({
    List<int>? pinnedStoriesIds,
    List<Story>? pinnedStories,
  }) {
    return PinState(
      pinnedStoriesIds: pinnedStoriesIds ?? this.pinnedStoriesIds,
      pinnedStories: pinnedStories ?? this.pinnedStories,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        pinnedStoriesIds,
        pinnedStories,
      ];
}
