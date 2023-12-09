part of 'preference_cubit.dart';

class PreferenceState extends Equatable {
  const PreferenceState({
    required this.preferences,
  });

  PreferenceState.init()
      : preferences = <Preference<dynamic>>{...Preference.allPreferences};

  final Set<Preference<dynamic>> preferences;

  PreferenceState copyWith({
    Set<Preference<dynamic>>? preferences,
  }) {
    return PreferenceState(
      preferences: preferences ?? this.preferences,
    );
  }

  PreferenceState copyWithPreference<T extends Preference<dynamic>>(
    T preference,
  ) {
    return PreferenceState(
      preferences: <Preference<dynamic>>{
        ...preferences.toList()
          ..remove(preference)
          ..insert(Preference.allPreferences.indexOf(preference), preference),
      },
    );
  }

  bool isOn<T extends BooleanPreference>(T preference) {
    return preferences
        .whereType<BooleanPreference>()
        .singleWhere(
          (BooleanPreference e) => e.runtimeType == preference.runtimeType,
        )
        .val;
  }

  bool _isOn<T extends BooleanPreference>() {
    return preferences
        .whereType<BooleanPreference>()
        .singleWhere(
          (BooleanPreference e) => e.runtimeType == T,
        )
        .val;
  }

  bool get notificationEnabled => _isOn<NotificationModePreference>();

  bool get complexStoryTileEnabled => _isOn<DisplayModePreference>();

  bool get eyeCandyEnabled => _isOn<EyeCandyModePreference>();

  bool get readerEnabled => _isOn<ReaderModePreference>();

  bool get markReadStoriesEnabled => _isOn<MarkReadStoriesModePreference>();

  bool get metadataEnabled => _isOn<MetadataModePreference>();

  bool get urlEnabled => _isOn<StoryUrlModePreference>();

  bool get tapAnywhereToCollapseEnabled => _isOn<CollapseModePreference>();

  bool get swipeGestureEnabled => _isOn<SwipeGesturePreference>();

  bool get autoScrollEnabled => _isOn<AutoScrollModePreference>();

  bool get customTabEnabled => _isOn<CustomTabPreference>();

  bool get manualPaginationEnabled => _isOn<ManualPaginationPreference>();

  bool get trueDarkModeEnabled => _isOn<TrueDarkModePreference>();

  bool get hapticFeedbackEnabled => _isOn<HapticFeedbackPreference>();

  bool get devModeEnabled => _isOn<DevMode>();

  double get textScaleFactor =>
      preferences.singleWhereType<TextScaleFactorPreference>().val;

  MaterialColor get appColor {
    return materialColors.elementAt(
      preferences.singleWhereType<AppColorPreference>().val,
    ) as MaterialColor;
  }

  List<StoryType> get tabs {
    final String result =
        preferences.singleWhereType<TabOrderPreference>().val.toString();
    final List<int> tabIndexes = List<int>.generate(
      result.length,
      (int index) => result.codeUnitAt(index) - 48,
    );
    final List<StoryType> tabs = tabIndexes
        .map((int index) => StoryType.values.elementAt(index))
        .toList();

    if (tabs.length < StoryType.values.length) {
      tabs.insert(0, StoryType.values.first);
    }
    return tabs;
  }

  StoryMarkingMode get storyMarkingMode => StoryMarkingMode.values
      .elementAt(preferences.singleWhereType<StoryMarkingModePreference>().val);

  FetchMode get fetchMode => FetchMode.values
      .elementAt(preferences.singleWhereType<FetchModePreference>().val);

  CommentsOrder get order => CommentsOrder.values
      .elementAt(preferences.singleWhereType<CommentsOrderPreference>().val);

  FontSize get fontSize => FontSize.values
      .elementAt(preferences.singleWhereType<FontSizePreference>().val);

  Font get font =>
      Font.values.elementAt(preferences.singleWhereType<FontPreference>().val);

  @override
  List<Object?> get props => <Object?>[
        ...preferences.map<dynamic>((Preference<dynamic> e) => e.val),
      ];
}
