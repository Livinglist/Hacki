part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.itemScreenArgs,
    required this.expanded,
    required this.enabled,
  });

  const SplitViewState.init()
      : enabled = false,
        expanded = false,
        itemScreenArgs = null;

  final bool enabled;
  final bool expanded;
  final ItemScreenArgs? itemScreenArgs;

  SplitViewState copyWith({
    bool? enabled,
    bool? expanded,
    ItemScreenArgs? itemScreenArgs,
  }) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      expanded: expanded ?? this.expanded,
      itemScreenArgs: itemScreenArgs ?? this.itemScreenArgs,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        enabled,
        expanded,
        itemScreenArgs,
      ];
}
