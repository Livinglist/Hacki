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

  bool get showNotification => _isOn<NotificationModePreference>();

  bool get showComplexStoryTile => _isOn<DisplayModePreference>();

  bool get showWebFirst => _isOn<NavigationModePreference>();

  bool get showEyeCandy => _isOn<EyeCandyModePreference>();

  bool get useTrueDark => _isOn<TrueDarkModePreference>();

  bool get useReader => _isOn<ReaderModePreference>();

  bool get markReadStories => _isOn<MarkReadStoriesModePreference>();

  bool get showMetadata => _isOn<MetadataModePreference>();

  bool get showUrl => _isOn<StoryUrlModePreference>();

  bool get tapAnywhereToCollapse => _isOn<CollapseModePreference>();

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

  FetchMode get fetchMode => FetchMode.values
      .elementAt(preferences.singleWhereType<FetchModePreference>().val);

  CommentsOrder get order => CommentsOrder.values
      .elementAt(preferences.singleWhereType<CommentsOrderPreference>().val);

  FontSize get fontSize => FontSize.values
      .elementAt(preferences.singleWhereType<FontSizePreference>().val);

  @override
  List<Object?> get props => <Object?>[
        ...preferences.map<dynamic>((Preference<dynamic> e) => e.val),
      ];
}
