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
    required this.showMetadata,
    required this.tapAnywhereToCollapse,
    required this.fetchMode,
    required this.order,
  });

  const PreferenceState.init()
      : showNotification = false,
        showComplexStoryTile = false,
        showWebFirst = false,
        showEyeCandy = false,
        useTrueDark = false,
        useReader = false,
        markReadStories = false,
        showMetadata = false,
        tapAnywhereToCollapse = false,
        fetchMode = FetchMode.eager,
        order = CommentsOrder.natural;

  final bool showNotification;
  final bool showComplexStoryTile;
  final bool showWebFirst;
  final bool showEyeCandy;
  final bool useTrueDark;
  final bool useReader;
  final bool markReadStories;
  final bool showMetadata;
  final bool tapAnywhereToCollapse;
  final FetchMode fetchMode;
  final CommentsOrder order;

  PreferenceState copyWith({
    bool? showNotification,
    bool? showComplexStoryTile,
    bool? showWebFirst,
    bool? showEyeCandy,
    bool? useTrueDark,
    bool? useReader,
    bool? markReadStories,
    bool? showMetadata,
    bool? tapAnywhereToCollapse,
    FetchMode? fetchMode,
    CommentsOrder? order,
  }) {
    return PreferenceState(
      showNotification: showNotification ?? this.showNotification,
      showComplexStoryTile: showComplexStoryTile ?? this.showComplexStoryTile,
      showWebFirst: showWebFirst ?? this.showWebFirst,
      showEyeCandy: showEyeCandy ?? this.showEyeCandy,
      useTrueDark: useTrueDark ?? this.useTrueDark,
      useReader: useReader ?? this.useReader,
      markReadStories: markReadStories ?? this.markReadStories,
      showMetadata: showMetadata ?? this.showMetadata,
      tapAnywhereToCollapse:
          tapAnywhereToCollapse ?? this.tapAnywhereToCollapse,
      fetchMode: fetchMode ?? this.fetchMode,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        showNotification,
        showComplexStoryTile,
        showWebFirst,
        showEyeCandy,
        useTrueDark,
        useReader,
        markReadStories,
        showMetadata,
        tapAnywhereToCollapse,
        fetchMode,
        order,
      ];
}
