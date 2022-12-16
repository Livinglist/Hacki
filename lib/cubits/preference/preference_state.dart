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

  bool get shouldShowComplexStoryTile => _isOn<DisplayModePreference>();

  bool get showWebFirst => _isOn<NavigationModePreference>();

  bool get showEyeCandy => _isOn<EyeCandyModePreference>();

  bool get useTrueDark => _isOn<TrueDarkModePreference>();

  bool get useReader => _isOn<ReaderModePreference>();

  bool get markReadStories => _isOn<MarkReadStoriesModePreference>();

  bool get showMetadata => _isOn<MetadataModePreference>();

  bool get tapAnywhereToCollapse => _isOn<CollapseModePreference>();

  FetchMode get fetchMode => FetchMode.values
      .elementAt(preferences.singleWhereType<FetchModePreference>().val);

  CommentsOrder get order => CommentsOrder.values
      .elementAt(preferences.singleWhereType<CommentsOrderPreference>().val);

  @override
  List<Object?> get props => <Object?>[
        ...preferences.map<dynamic>((Preference<dynamic> e) => e.val),
      ];
}
