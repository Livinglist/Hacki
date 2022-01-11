part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showComplexStoryTile,
    required this.showWebFirst,
    required this.showEyeCandy,
  });

  const PreferenceState.init()
      : showComplexStoryTile = false,
        showWebFirst = false,
        showEyeCandy = false;

  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showEyeCandy;

  PreferenceState copyWith({
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showEyeCandy,
  }) {
    return PreferenceState(
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
    );
  }

  @override
  List<Object?> get props => [
        showComplexStoryTile,
        showWebFirst,
        showEyeCandy,
      ];
}
