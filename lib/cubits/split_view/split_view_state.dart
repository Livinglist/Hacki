part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.storyScreenArgs,
    required this.expanded,
    required this.enabled,
  });

  const SplitViewState.init()
      : enabled = false,
        expanded = false,
        storyScreenArgs = null;

  final bool enabled;
  final bool expanded;
  final StoryScreenArgs? storyScreenArgs;

  SplitViewState copyWith({
    bool? enabled,
    bool? expanded,
    StoryScreenArgs? storyScreenArgs,
  }) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      expanded: expanded ?? this.expanded,
      storyScreenArgs: storyScreenArgs ?? this.storyScreenArgs,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        enabled,
        expanded,
        storyScreenArgs,
      ];
}
