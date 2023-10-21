import 'dart:collection';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:hacki/models/displayable.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/palette.dart';

abstract class Preference<T> extends Equatable with SettingsDisplayable {
  const Preference({required this.val});

  final T val;

  String get key;

  Preference<T> copyWith({required T? val});

  static final List<Preference<dynamic>> allPreferences =
      UnmodifiableListView<Preference<dynamic>>(
    <Preference<dynamic>>[
      // Order of these preferences does not matter.
      FetchModePreference(),
      CommentsOrderPreference(),
      FontPreference(),
      FontSizePreference(),
      TabOrderPreference(),
      StoryMarkingModePreference(),
      AppColorPreference(),
      // Order of items below matters and
      // reflects the order on settings screen.
      const DisplayModePreference(),
      const MetadataModePreference(),
      const StoryUrlModePreference(),
      const MarkReadStoriesModePreference(),
      const NotificationModePreference(),
      const SwipeGesturePreference(),
      const AutoScrollModePreference(),
      const CollapseModePreference(),
      const ReaderModePreference(),
      const EyeCandyModePreference(),
    ],
  );

  @override
  List<Object?> get props => <Object?>[key];
}

abstract class BooleanPreference extends Preference<bool> {
  const BooleanPreference({required super.val});
}

abstract class IntPreference extends Preference<int> {
  const IntPreference({required super.val});
}

const bool _notificationModeDefaultValue = true;
const bool _swipeGestureModeDefaultValue = false;
const bool _displayModeDefaultValue = true;
const bool _eyeCandyModeDefaultValue = false;
const bool _readerModeDefaultValue = true;
const bool _markReadStoriesModeDefaultValue = true;
const bool _metadataModeDefaultValue = true;
const bool _storyUrlModeDefaultValue = true;
const bool _collapseModeDefaultValue = true;
const bool _autoScrollModeDefaultValue = true;
final int _fetchModeDefaultValue = FetchMode.eager.index;
final int _commentsOrderDefaultValue = CommentsOrder.natural.index;
final int _fontSizeDefaultValue = FontSize.regular.index;
final int _appColorDefaultValue = materialColors.indexOf(Palette.deepOrange);
final int _fontDefaultValue = Font.roboto.index;
final int _tabOrderDefaultValue =
    StoryType.convertToSettingsValue(StoryType.values);
final int _markStoriesAsReadWhenPreferenceDefaultValue =
    StoryMarkingMode.tap.index;

class SwipeGesturePreference extends BooleanPreference {
  const SwipeGesturePreference({bool? val})
      : super(val: val ?? _swipeGestureModeDefaultValue);

  @override
  SwipeGesturePreference copyWith({required bool? val}) {
    return SwipeGesturePreference(val: val);
  }

  @override
  String get key => 'swipeGestureMode';

  @override
  String get title => 'Enable Swipe Gesture';

  @override
  String get subtitle =>
      '''enable swipe gesture for switching between tabs. If enabled, long press on Story tile to trigger the action menu.''';
}

class NotificationModePreference extends BooleanPreference {
  const NotificationModePreference({bool? val})
      : super(val: val ?? _notificationModeDefaultValue);

  @override
  NotificationModePreference copyWith({required bool? val}) {
    return NotificationModePreference(val: val);
  }

  @override
  String get key => 'notificationMode';

  @override
  String get title => 'Notification on New Reply';

  @override
  String get subtitle =>
      '''Hacki scans for new replies to your 15 most recent comments or stories every 5 minutes while the app is running in the foreground.''';
}

class CollapseModePreference extends BooleanPreference {
  const CollapseModePreference({bool? val})
      : super(val: val ?? _collapseModeDefaultValue);

  @override
  CollapseModePreference copyWith({required bool? val}) {
    return CollapseModePreference(val: val);
  }

  @override
  String get key => 'collapseMode';

  @override
  String get title => 'Tap Anywhere to Collapse';

  @override
  String get subtitle =>
      '''if disabled, tap on the top of comment tile to collapse.''';
}

class AutoScrollModePreference extends BooleanPreference {
  const AutoScrollModePreference({bool? val})
      : super(val: val ?? _autoScrollModeDefaultValue);

  @override
  AutoScrollModePreference copyWith({required bool? val}) {
    return AutoScrollModePreference(val: val);
  }

  @override
  String get key => 'autoScrollMode';

  @override
  String get title => 'Auto-scroll on collapsing';

  @override
  String get subtitle =>
      '''automatically scroll to next comment when you collapse a comment.''';
}

/// The value deciding whether or not the story
/// tile should display link preview. Defaults to true.
class DisplayModePreference extends BooleanPreference {
  const DisplayModePreference({bool? val})
      : super(val: val ?? _displayModeDefaultValue);

  @override
  DisplayModePreference copyWith({required bool? val}) {
    return DisplayModePreference(val: val);
  }

  @override
  String get key => 'displayMode';

  @override
  String get title => 'Complex Story Tile';

  @override
  String get subtitle => 'show web preview in story tile.';
}

class MetadataModePreference extends BooleanPreference {
  const MetadataModePreference({bool? val})
      : super(val: val ?? _metadataModeDefaultValue);

  @override
  MetadataModePreference copyWith({required bool? val}) {
    return MetadataModePreference(val: val);
  }

  @override
  String get key => 'metadataMode';

  @override
  String get title => 'Show Metadata';

  @override
  String get subtitle =>
      '''show number of comments and post date in story tile.''';
}

class StoryUrlModePreference extends BooleanPreference {
  const StoryUrlModePreference({bool? val})
      : super(val: val ?? _storyUrlModeDefaultValue);

  @override
  StoryUrlModePreference copyWith({required bool? val}) {
    return StoryUrlModePreference(val: val);
  }

  @override
  String get key => 'storyUrlMode';

  @override
  String get title => 'Show Url';

  @override
  String get subtitle => '''show url in story tile.''';
}

class ReaderModePreference extends BooleanPreference {
  const ReaderModePreference({bool? val})
      : super(val: val ?? _readerModeDefaultValue);

  @override
  ReaderModePreference copyWith({required bool? val}) {
    return ReaderModePreference(val: val);
  }

  @override
  String get key => 'readerMode';

  @override
  String get title => 'Use Reader';

  @override
  String get subtitle =>
      '''enter reader mode in Safari directly when it is available.''';

  @override
  bool get isDisplayable => Platform.isIOS;
}

class MarkReadStoriesModePreference extends BooleanPreference {
  const MarkReadStoriesModePreference({bool? val})
      : super(val: val ?? _markReadStoriesModeDefaultValue);

  @override
  MarkReadStoriesModePreference copyWith({required bool? val}) {
    return MarkReadStoriesModePreference(val: val);
  }

  @override
  String get key => 'markReadStoriesMode';

  @override
  String get title => 'Mark Read Stories';

  @override
  String get subtitle => 'grey out stories you have read.';
}

class EyeCandyModePreference extends BooleanPreference {
  const EyeCandyModePreference({bool? val})
      : super(val: val ?? _eyeCandyModeDefaultValue);

  @override
  EyeCandyModePreference copyWith({required bool? val}) {
    return EyeCandyModePreference(val: val);
  }

  @override
  String get key => 'eyeCandyMode';

  @override
  String get title => 'Eye Candy';

  @override
  String get subtitle => 'some sort of magic.';
}

class FetchModePreference extends IntPreference {
  FetchModePreference({int? val}) : super(val: val ?? _fetchModeDefaultValue);

  @override
  FetchModePreference copyWith({required int? val}) {
    return FetchModePreference(val: val);
  }

  @override
  String get key => 'fetchMode';

  @override
  String get title => 'Default fetch mode';
}

class CommentsOrderPreference extends IntPreference {
  CommentsOrderPreference({int? val})
      : super(val: val ?? _commentsOrderDefaultValue);

  @override
  CommentsOrderPreference copyWith({required int? val}) {
    return CommentsOrderPreference(val: val);
  }

  @override
  String get key => 'commentsOrder';

  @override
  String get title => 'Default comments order';
}

class FontPreference extends IntPreference {
  FontPreference({int? val}) : super(val: val ?? _fontDefaultValue);

  @override
  FontPreference copyWith({required int? val}) {
    return FontPreference(val: val);
  }

  @override
  String get key => 'font';

  @override
  String get title => 'Default font';
}

class FontSizePreference extends IntPreference {
  FontSizePreference({int? val}) : super(val: val ?? _fontSizeDefaultValue);

  @override
  FontSizePreference copyWith({required int? val}) {
    return FontSizePreference(val: val);
  }

  @override
  String get key => 'fontSize';

  @override
  String get title => 'Default font size';
}

class TabOrderPreference extends IntPreference {
  TabOrderPreference({int? val}) : super(val: val ?? _tabOrderDefaultValue);

  @override
  TabOrderPreference copyWith({required int? val}) {
    return TabOrderPreference(val: val);
  }

  @override
  String get key => 'tabOrder';

  @override
  String get title => 'Tab order';
}

class StoryMarkingModePreference extends IntPreference {
  StoryMarkingModePreference({int? val})
      : super(val: val ?? _markStoriesAsReadWhenPreferenceDefaultValue);

  @override
  StoryMarkingModePreference copyWith({required int? val}) {
    return StoryMarkingModePreference(val: val);
  }

  @override
  String get key => 'storyMarkingMode';

  @override
  String get title => 'Mark a Story as Read on';
}

class AppColorPreference extends IntPreference {
  AppColorPreference({int? val}) : super(val: val ?? _appColorDefaultValue);

  @override
  AppColorPreference copyWith({required int? val}) {
    return AppColorPreference(val: val);
  }

  @override
  String get key => 'appColor';

  @override
  String get title => 'Accent Color';
}
