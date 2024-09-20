import 'dart:collection';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:hacki/models/displayable.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/palette.dart';

abstract final class Preference<T> extends Equatable with SettingsDisplayable {
  const Preference({required this.val});

  final T val;

  String get key;

  Preference<T> copyWith({required T? val});

  static final List<Preference<dynamic>> allPreferences =
      UnmodifiableListView<Preference<dynamic>>(
    <Preference<dynamic>>[
      /// Order of these preferences does not matter.
      FetchModePreference(),
      CommentsOrderPreference(),
      FontPreference(),
      FontSizePreference(),
      TabOrderPreference(),
      StoryMarkingModePreference(),
      AppColorPreference(),
      DateFormatPreference(),
      HackerNewsDataSourcePreference(),
      const TextScaleFactorPreference(),

      /// Order of items below matters and
      /// reflects the order on settings screen.
      const DisplayModePreference(),
      const FaviconModePreference(),
      const MetadataModePreference(),
      const StoryUrlModePreference(),

      /// Divider.
      const MarkReadStoriesModePreference(),

      /// Divider.
      const NotificationModePreference(),
      const AutoScrollModePreference(),
      const CollapseModePreference(),
      const ReaderModePreference(),
      const CustomTabPreference(),
      const ManualPaginationPreference(),
      const SwipeGesturePreference(),
      const HapticFeedbackPreference(),
      const EyeCandyModePreference(),
      const TrueDarkModePreference(),
      const DevMode(),
    ],
  );

  @override
  List<Object?> get props => <Object?>[key];
}

abstract final class BooleanPreference extends Preference<bool> {
  const BooleanPreference({required super.val});
}

abstract final class IntPreference extends Preference<int> {
  const IntPreference({required super.val});
}

abstract final class DoublePreference extends Preference<double> {
  const DoublePreference({required super.val});
}

final class DevMode extends BooleanPreference {
  const DevMode({bool? val}) : super(val: val ?? _devModeDefaultValue);

  static const bool _devModeDefaultValue = false;

  @override
  DevMode copyWith({required bool? val}) {
    return DevMode(val: val);
  }

  @override
  String get key => 'devMode';

  @override
  String get title => 'Dev Mode';

  @override
  String get subtitle => '';

  @override
  bool get isDisplayable => false;
}

final class SwipeGesturePreference extends BooleanPreference {
  const SwipeGesturePreference({bool? val})
      : super(val: val ?? _swipeGestureModeDefaultValue);

  static const bool _swipeGestureModeDefaultValue = false;

  @override
  SwipeGesturePreference copyWith({required bool? val}) {
    return SwipeGesturePreference(val: val);
  }

  @override
  String get key => 'swipeGestureMode';

  @override
  String get title => 'Swipe Gesture';

  @override
  String get subtitle =>
      '''enable swipe gesture for switching between tabs. If enabled, long press on Story tile to trigger the action menu and double tap to open the url.''';
}

final class NotificationModePreference extends BooleanPreference {
  const NotificationModePreference({bool? val})
      : super(val: val ?? _notificationModeDefaultValue);

  static const bool _notificationModeDefaultValue = true;

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

final class CollapseModePreference extends BooleanPreference {
  const CollapseModePreference({bool? val})
      : super(val: val ?? _collapseModeDefaultValue);

  static const bool _collapseModeDefaultValue = true;

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

final class AutoScrollModePreference extends BooleanPreference {
  const AutoScrollModePreference({bool? val})
      : super(val: val ?? _autoScrollModeDefaultValue);

  static const bool _autoScrollModeDefaultValue = true;

  @override
  AutoScrollModePreference copyWith({required bool? val}) {
    return AutoScrollModePreference(val: val);
  }

  @override
  String get key => 'autoScrollMode';

  @override
  String get title => 'Auto-scroll on Collapsing';

  @override
  String get subtitle =>
      '''automatically scroll to next comment when you collapse a comment.''';
}

/// The value deciding whether or not the story
/// tile should display link preview. Defaults to true.
final class DisplayModePreference extends BooleanPreference {
  const DisplayModePreference({bool? val})
      : super(val: val ?? _displayModeDefaultValue);

  static const bool _displayModeDefaultValue = true;

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

final class FaviconModePreference extends BooleanPreference {
  const FaviconModePreference({bool? val})
      : super(val: val ?? _faviconModePreferenceDefaultValue);

  static const bool _faviconModePreferenceDefaultValue = true;

  @override
  FaviconModePreference copyWith({required bool? val}) {
    return FaviconModePreference(val: val);
  }

  @override
  String get key => 'faviconMode';

  @override
  String get title => 'Show Favicon';

  @override
  String get subtitle => 'show favicon in story tile.';
}

final class MetadataModePreference extends BooleanPreference {
  const MetadataModePreference({bool? val})
      : super(val: val ?? _metadataModeDefaultValue);

  static const bool _metadataModeDefaultValue = true;

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

final class StoryUrlModePreference extends BooleanPreference {
  const StoryUrlModePreference({bool? val})
      : super(val: val ?? _storyUrlModeDefaultValue);

  static const bool _storyUrlModeDefaultValue = true;

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

final class ReaderModePreference extends BooleanPreference {
  const ReaderModePreference({bool? val})
      : super(val: val ?? _readerModeDefaultValue);

  static const bool _readerModeDefaultValue = true;

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

final class MarkReadStoriesModePreference extends BooleanPreference {
  const MarkReadStoriesModePreference({bool? val})
      : super(val: val ?? _markReadStoriesModeDefaultValue);

  static const bool _markReadStoriesModeDefaultValue = true;

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

final class EyeCandyModePreference extends BooleanPreference {
  const EyeCandyModePreference({bool? val})
      : super(val: val ?? _eyeCandyModeDefaultValue);

  static const bool _eyeCandyModeDefaultValue = false;

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

final class ManualPaginationPreference extends BooleanPreference {
  const ManualPaginationPreference({bool? val})
      : super(val: val ?? _paginationModeDefaultValue);

  static const bool _paginationModeDefaultValue = false;

  @override
  ManualPaginationPreference copyWith({required bool? val}) {
    return ManualPaginationPreference(val: val);
  }

  @override
  String get key => 'paginationMode';

  @override
  String get title => 'Manual Pagination';

  @override
  String get subtitle => '''so you can get stuff done.''';
}

/// Whether or not to use Custom Tabs for launching URLs.
/// If false, default browser will be used.
///
/// https://developer.chrome.com/docs/android/custom-tabs/
final class CustomTabPreference extends BooleanPreference {
  const CustomTabPreference({bool? val})
      : super(val: val ?? _customTabModeDefaultValue);

  static const bool _customTabModeDefaultValue = false;

  @override
  CustomTabPreference copyWith({required bool? val}) {
    return CustomTabPreference(val: val);
  }

  @override
  String get key => 'customTabPreference';

  @override
  String get title => 'Use Custom Tabs';

  @override
  String get subtitle =>
      '''use Custom tabs for URLs. If disabled, default browser is used instead.''';

  @override
  bool get isDisplayable => Platform.isAndroid;
}

final class TrueDarkModePreference extends BooleanPreference {
  const TrueDarkModePreference({bool? val})
      : super(val: val ?? _trueDarkModeDefaultValue);

  static const bool _trueDarkModeDefaultValue = false;

  @override
  TrueDarkModePreference copyWith({required bool? val}) {
    return TrueDarkModePreference(val: val);
  }

  @override
  String get key => 'trueDarkMode';

  @override
  String get title => 'True Dark Mode';

  @override
  String get subtitle => 'real dark.';
}

final class HapticFeedbackPreference extends BooleanPreference {
  const HapticFeedbackPreference({bool? val})
      : super(val: val ?? _hapticFeedbackModeDefaultValue);

  static const bool _hapticFeedbackModeDefaultValue = true;

  @override
  HapticFeedbackPreference copyWith({required bool? val}) {
    return HapticFeedbackPreference(val: val);
  }

  @override
  String get key => 'hapticFeedbackMode';

  @override
  String get title => 'Haptic Feedback';

  @override
  String get subtitle => '';
}

final class FetchModePreference extends IntPreference {
  FetchModePreference({int? val}) : super(val: val ?? _fetchModeDefaultValue);

  static final int _fetchModeDefaultValue = FetchMode.eager.index;

  @override
  FetchModePreference copyWith({required int? val}) {
    return FetchModePreference(val: val);
  }

  @override
  String get key => 'fetchMode';

  @override
  String get title => 'Default fetch mode';
}

final class CommentsOrderPreference extends IntPreference {
  CommentsOrderPreference({int? val})
      : super(val: val ?? _commentsOrderDefaultValue);

  static final int _commentsOrderDefaultValue = CommentsOrder.natural.index;

  @override
  CommentsOrderPreference copyWith({required int? val}) {
    return CommentsOrderPreference(val: val);
  }

  @override
  String get key => 'commentsOrder';

  @override
  String get title => 'Default comments order';
}

final class FontPreference extends IntPreference {
  FontPreference({int? val}) : super(val: val ?? _fontDefaultValue);

  static final int _fontDefaultValue = Font.robotoSlab.index;

  @override
  FontPreference copyWith({required int? val}) {
    return FontPreference(val: val);
  }

  @override
  String get key => 'font';

  @override
  String get title => 'Default font';
}

final class FontSizePreference extends IntPreference {
  FontSizePreference({int? val}) : super(val: val ?? _fontSizeDefaultValue);

  static final int _fontSizeDefaultValue = FontSize.regular.index;

  @override
  FontSizePreference copyWith({required int? val}) {
    return FontSizePreference(val: val);
  }

  @override
  String get key => 'fontSize';

  @override
  String get title => 'Default font size';
}

final class TabOrderPreference extends IntPreference {
  TabOrderPreference({int? val}) : super(val: val ?? _tabOrderDefaultValue);

  static final int _tabOrderDefaultValue =
      StoryType.convertToSettingsValue(StoryType.values);

  @override
  TabOrderPreference copyWith({required int? val}) {
    return TabOrderPreference(val: val);
  }

  @override
  String get key => 'tabOrder';

  @override
  String get title => 'Tab order';
}

final class StoryMarkingModePreference extends IntPreference {
  StoryMarkingModePreference({int? val})
      : super(val: val ?? _markStoriesAsReadWhenPreferenceDefaultValue);

  static final int _markStoriesAsReadWhenPreferenceDefaultValue =
      StoryMarkingMode.tap.index;

  @override
  StoryMarkingModePreference copyWith({required int? val}) {
    return StoryMarkingModePreference(val: val);
  }

  @override
  String get key => 'storyMarkingMode';

  @override
  String get title => 'Mark as Read on';
}

final class AppColorPreference extends IntPreference {
  AppColorPreference({int? val}) : super(val: val ?? _appColorDefaultValue);

  static final int _appColorDefaultValue =
      materialColors.indexOf(Palette.deepOrange);

  @override
  AppColorPreference copyWith({required int? val}) {
    return AppColorPreference(val: val);
  }

  @override
  String get key => 'appColor';

  @override
  String get title => 'Accent Color';
}

final class TextScaleFactorPreference extends DoublePreference {
  const TextScaleFactorPreference({double? val})
      : super(val: val ?? _textScaleFactorDefaultValue);

  static const double _textScaleFactorDefaultValue = 1;

  @override
  TextScaleFactorPreference copyWith({required double? val}) {
    return TextScaleFactorPreference(val: val);
  }

  @override
  String get key => 'appTextScaleFactor';

  @override
  String get title => 'Default text scale factor';
}

final class DateFormatPreference extends IntPreference {
  DateFormatPreference({int? val}) : super(val: val ?? _dateFormatDefaultValue);

  static final int _dateFormatDefaultValue = DateDisplayFormat.timeAgo.index;

  @override
  DateFormatPreference copyWith({required int? val}) {
    return DateFormatPreference(val: val);
  }

  @override
  String get key => 'dateFormat';

  @override
  String get title => 'Date Format';
}

final class HackerNewsDataSourcePreference extends IntPreference {
  HackerNewsDataSourcePreference({int? val})
      : super(val: val ?? _hackerNewsDataSourceDefaultValue);

  static final int _hackerNewsDataSourceDefaultValue =
      HackerNewsDataSource.api.index;

  @override
  HackerNewsDataSourcePreference copyWith({required int? val}) {
    return HackerNewsDataSourcePreference(val: val);
  }

  @override
  String get key => 'hackerNewsDataSource';

  @override
  String get title => 'Date Source';
}
