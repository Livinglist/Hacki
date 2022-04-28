part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.storyScreenArgs,
    required this.enabled,
  });

  const SplitViewState.init()
      : enabled = false,
        storyScreenArgs = null;

  final bool enabled;
  final StoryScreenArgs? storyScreenArgs;

  SplitViewState copyWith({bool? enabled, StoryScreenArgs? storyScreenArgs}) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      storyScreenArgs: storyScreenArgs ?? this.storyScreenArgs,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        enabled,
        storyScreenArgs,
      ];
}
