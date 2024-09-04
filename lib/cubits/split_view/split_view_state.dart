part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.itemScreenArgs,
    required this.expanded,
    required this.enabled,
    required this.resizingAnimationDuration,
    this.submissionPanelWidth,
  });

  const SplitViewState.init()
      : enabled = false,
        expanded = false,
        submissionPanelWidth = null,
        resizingAnimationDuration = Duration.zero,
        itemScreenArgs = null;

  final bool enabled;
  final bool expanded;
  final double? submissionPanelWidth;
  final Duration resizingAnimationDuration;
  final ItemScreenArgs? itemScreenArgs;

  SplitViewState copyWith({
    bool? enabled,
    bool? expanded,
    double? submissionPanelWidth,
    Duration? resizingAnimationDuration,
    ItemScreenArgs? itemScreenArgs,
  }) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      expanded: expanded ?? this.expanded,
      submissionPanelWidth: submissionPanelWidth ?? this.submissionPanelWidth,
      resizingAnimationDuration:
          resizingAnimationDuration ?? this.resizingAnimationDuration,
      itemScreenArgs: itemScreenArgs ?? this.itemScreenArgs,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        enabled,
        expanded,
        submissionPanelWidth,
        resizingAnimationDuration,
        itemScreenArgs,
      ];
}
