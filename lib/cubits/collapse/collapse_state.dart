part of 'collapse_cubit.dart';

class CollapseState extends Equatable {
  const CollapseState({
    required this.collapsed,
    required this.hidden,
    required this.locked,
    required this.collapsedCount,
  });

  const CollapseState.init()
      : collapsed = false,
        hidden = false,
        locked = false,
        collapsedCount = 0;

  final bool collapsed;

  /// The value determining whether or not the comment should show up in the
  /// screen, this is true when the comment's parent is collapsed.
  final bool hidden;

  /// The value determining whether or not the comment is collapsable.
  /// If [locked] is true then the comment is not collapsable and vice versa.
  final bool locked;

  /// The number of children under this collapsed comment.
  final int collapsedCount;

  CollapseState copyWith({
    bool? collapsed,
    bool? hidden,
    bool? locked,
    int? collapsedCount,
  }) {
    return CollapseState(
      collapsed: collapsed ?? this.collapsed,
      hidden: hidden ?? this.hidden,
      locked: locked ?? this.locked,
      collapsedCount: collapsedCount ?? this.collapsedCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        collapsed,
        hidden,
        locked,
        collapsedCount,
      ];
}
