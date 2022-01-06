part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showComplexStoryTile,
    required this.showWebFirst,
  });

  const PreferenceState.init()
      : showComplexStoryTile = false,
        showWebFirst = false;

  final bool showComplexStoryTile;
  final bool showWebFirst;

  PreferenceState copyWith({
    bool? showComplexStoryTile,
    bool? showWebFirst,
  }) {
    return PreferenceState(
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
    );
  }

  @override
  List<Object?> get props => [
        showComplexStoryTile,
        showWebFirst,
      ];
}
