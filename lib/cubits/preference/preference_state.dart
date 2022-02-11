part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showNotification,
    required this.showComplexStoryTile,
    required this.showWebFirst,
    required this.showCommentBorder,
    required this.showEyeCandy,
    required this.useTrueDark,
  });

  const PreferenceState.init()
      : showNotification = false,
        showComplexStoryTile = false,
        showWebFirst = false,
        showCommentBorder = false,
        showEyeCandy = false,
        useTrueDark = false;

  final bool showNotification;
  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showCommentBorder;
  final bool showEyeCandy;
  final bool useTrueDark;

  PreferenceState copyWith({
    bool? showNotification,
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showCommentBorder,
    bool? showEyeCandy,
    bool? useTrueDark,
  }) {
    return PreferenceState(
      showNotification: showNotification ?? this.showNotification,
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showCommentBorder: showCommentBorder ?? this.showCommentBorder,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
      useTrueDark: useTrueDark ?? this.useTrueDark,
    );
  }

  @override
  List<Object?> get props => [
        showNotification,
        showComplexStoryTile,
        showWebFirst,
        showCommentBorder,
        showEyeCandy,
        useTrueDark,
      ];
}
