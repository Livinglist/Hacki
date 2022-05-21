part of 'collapse_cubit.dart';

class CollapseState extends Equatable {
  const CollapseState({
    required this.collapsed,
    required this.hidden,
    required this.collapsedCount,
  });

  const CollapseState.init()
      : collapsed = false,
        hidden = false,
        collapsedCount = 0;

  final bool collapsed;
  final bool hidden;
  final int collapsedCount;

  CollapseState copyWith({
    bool? collapsed,
    bool? hidden,
    int? collapsedCount,
  }) {
    return CollapseState(
      collapsed: collapsed ?? this.collapsed,
      hidden: hidden ?? this.hidden,
      collapsedCount: collapsedCount ?? this.collapsedCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        collapsed,
        hidden,
        collapsedCount,
      ];
}
