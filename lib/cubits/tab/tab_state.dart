part of 'tab_cubit.dart';

class TabState extends Equatable {
  const TabState({required this.tabs});

  TabState.init() : tabs = <StoryType>[];

  final List<StoryType>? tabs;

  TabState copyWith({
    List<StoryType>? tabs,
  }) {
    return TabState(tabs: tabs ?? this.tabs);
  }

  @override
  List<Object?> get props => <Object?>[tabs];
}
