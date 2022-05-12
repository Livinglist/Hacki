part of 'collapse_cubit.dart';

class CollapseState extends Equatable {
  const CollapseState({required this.collapsed});

  const CollapseState.init() : collapsed = false;

  final bool collapsed;

  CollapseState copyWith({bool? collapsed}) {
    return CollapseState(
      collapsed: collapsed ?? this.collapsed,
    );
  }

  @override
  List<Object?> get props => <Object?>[collapsed];
}
