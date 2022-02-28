part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.showNotification,
    required this.showComplexStoryTile,
    required this.showWebFirst,
    required this.showEyeCandy,
    required this.useTrueDark,
    required this.useReader,
    required this.markReadStories,
  });

  const PreferenceState.init()
      : showNotification = false,
        showComplexStoryTile = false,
        showWebFirst = false,
        showEyeCandy = false,
        useTrueDark = false,
        useReader = false,
        markReadStories = false;

  final bool showNotification;
  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showEyeCandy;
  final bool useTrueDark;
  final bool useReader;
  final bool markReadStories;

  PreferenceState copyWith({
    bool? showNotification,
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showEyeCandy,
    bool? useTrueDark,
    bool? useReader,
    bool? markReadStories,
  }) {
    return PreferenceState(
      showNotification: showNotification ?? this.showNotification,
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
      useTrueDark: useTrueDark ?? this.useTrueDark,
      useReader: useReader ?? this.useReader,
      markReadStories: markReadStories ?? this.markReadStories,
    );
  }

  @override
  List<Object?> get props => [
        showNotification,
        showComplexStoryTile,
        showWebFirst,
        showEyeCandy,
        useTrueDark,
        useReader,
        markReadStories,
      ];
}
