part of 'pin_cubit.dart';

class PinState extends Equatable {
  const PinState({
    required this.pinnedStoriesIds,
    required this.pinnedStories,
    required this.status,
  });

  PinState.init()
      : pinnedStoriesIds = <int>[],
        pinnedStories = <Story>[],
        status = Status.idle;

  final List<int> pinnedStoriesIds;
  final List<Story> pinnedStories;
  final Status status;

  PinState copyWith({
    List<int>? pinnedStoriesIds,
    List<Story>? pinnedStories,
    Status? status,
  }) {
    return PinState(
      pinnedStoriesIds: pinnedStoriesIds ?? this.pinnedStoriesIds,
      pinnedStories: pinnedStories ?? this.pinnedStories,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        pinnedStoriesIds,
        pinnedStories,
        status,
      ];
}
