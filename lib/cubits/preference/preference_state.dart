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

  bool get isNotificationEnabled => _isOn<NotificationModePreference>();

  bool get isComplexStoryTileEnabled => _isOn<DisplayModePreference>();

  bool get isFaviconEnabled => _isOn<FaviconModePreference>();

  bool get isEyeCandyEnabled => _isOn<EyeCandyModePreference>();

  bool get isReaderEnabled => _isOn<ReaderModePreference>();

  bool get isMarkReadStoriesEnabled => _isOn<MarkReadStoriesModePreference>();

  bool get isMetadataEnabled => _isOn<MetadataModePreference>();

  bool get isUrlEnabled => _isOn<StoryUrlModePreference>();

  bool get isTapAnywhereToCollapseEnabled => _isOn<CollapseModePreference>();

  bool get isSwipeGestureEnabled => _isOn<SwipeGesturePreference>();

  bool get isAutoScrollEnabled => _isOn<AutoScrollModePreference>();

  bool get isCustomTabEnabled => _isOn<CustomTabPreference>();

  bool get isManualPaginationEnabled => _isOn<ManualPaginationPreference>();

  bool get isTrueDarkModeEnabled => _isOn<TrueDarkModePreference>();

  bool get isHapticFeedbackEnabled => _isOn<HapticFeedbackPreference>();

  bool get isDevModeEnabled => _isOn<DevMode>();

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

  DateDisplayFormat get displayDateFormat => DateDisplayFormat.values
      .elementAt(preferences.singleWhereType<DateFormatPreference>().val);

  @override
  List<Object?> get props => <Object?>[
        ...preferences.map<dynamic>((Preference<dynamic> e) => e.val),
      ];
}
