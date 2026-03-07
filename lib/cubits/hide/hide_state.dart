part of 'hide_cubit.dart';

class HideState extends Equatable {
  const HideState({
    required this.hiddenStoryIds,
  });

  HideState.init() : hiddenStoryIds = <int>[];

  final List<int> hiddenStoryIds;

  HideState copyWith({
    List<int>? hiddenStoryIds,
  }) {
    return HideState(
      hiddenStoryIds: hiddenStoryIds ?? this.hiddenStoryIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[hiddenStoryIds];
}
