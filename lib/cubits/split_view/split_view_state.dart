part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.itemScreenArgs,
    required this.expanded,
    required this.enabled,
    required this.resizingAnimationDuration,
    this.submissionPanelWidth,
    this.showDetail = false,
  });

  const SplitViewState.init()
    : enabled = false,
      expanded = false,
      submissionPanelWidth = null,
      resizingAnimationDuration = Duration.zero,
      itemScreenArgs = null,
      showDetail = false;

  final bool enabled;

  /// Whether the selected thread is visible when only one pane fits.
  final bool showDetail;
  final bool expanded;
  final double? submissionPanelWidth;
  final Duration resizingAnimationDuration;
  final ItemScreenArgs? itemScreenArgs;

  SplitViewState copyWith({
    bool? enabled,
    bool? showDetail,
    bool? expanded,
    double? submissionPanelWidth,
    Duration? resizingAnimationDuration,
    ItemScreenArgs? itemScreenArgs,
  }) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      showDetail: showDetail ?? this.showDetail,
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
    showDetail,
    expanded,
    submissionPanelWidth,
    resizingAnimationDuration,
    itemScreenArgs,
  ];
}
