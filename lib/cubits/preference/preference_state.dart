part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showNotification,
    required this.showComplexStoryTile,
    required this.showWebFirst,
    required this.showCommentBorder,
    required this.showEyeCandy,
    required this.useTrueDark,
    required this.useReader,
    required this.showImage,
  });

  const PreferenceState.init()
      : showNotification = false,
        showComplexStoryTile = false,
        showWebFirst = false,
        showCommentBorder = false,
        showEyeCandy = false,
        useTrueDark = false,
        useReader = false,
        showImage = false;

  final bool showNotification;
  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showCommentBorder;
  final bool showEyeCandy;
  final bool useTrueDark;
  final bool useReader;
  final bool showImage;

  PreferenceState copyWith({
    bool? showNotification,
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showCommentBorder,
    bool? showEyeCandy,
    bool? useTrueDark,
    bool? useReader,
    bool? showImage,
  }) {
    return PreferenceState(
      showNotification: showNotification ?? this.showNotification,
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showCommentBorder: showCommentBorder ?? this.showCommentBorder,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
      useTrueDark: useTrueDark ?? this.useTrueDark,
      useReader: useReader ?? this.useReader,
      showImage: showImage ?? this.showImage,
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
        useReader,
        showImage,
      ];
}
