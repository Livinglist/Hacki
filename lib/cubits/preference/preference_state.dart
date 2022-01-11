part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showComplexStoryTile,
    required this.showWebFirst,
    required this.showCommentBorder,
    required this.showEyeCandy,
  });

  const PreferenceState.init()
      : showComplexStoryTile = false,
        showWebFirst = false,
        showCommentBorder = false,
        showEyeCandy = false;

  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showCommentBorder;
  final bool showEyeCandy;

  PreferenceState copyWith({
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showCommentBorder,
    bool? showEyeCandy,
  }) {
    return PreferenceState(
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showCommentBorder: showCommentBorder ?? this.showCommentBorder,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
    );
  }

  @override
  List<Object?> get props => [
        showComplexStoryTile,
        showWebFirst,
        showCommentBorder,
        showEyeCandy,
      ];
}
