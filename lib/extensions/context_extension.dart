import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/stories/stories_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/styles/dimens.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

extension ContextExtension on BuildContext {
  void onStoryTapped(Story story) {
    final PreferenceState prefState = read<PreferenceCubit>().state;
    final bool shouldUseReader = prefState.isReaderEnabled;
    final StoryMarkingMode storyMarkingMode = prefState.storyMarkingMode;
    final bool isOfflineReading = read<StoriesBloc>().state.isOfflineReading;
    final bool isSplitViewEnabled = read<SplitViewCubit>().state.enabled;
    final bool isMarkReadStoriesEnabled = prefState.isMarkReadStoriesEnabled;

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final bool isJobWithLink = story.isJob && story.url.isNotEmpty;

    if (isJobWithLink) {
      read<ReminderCubit>().removeLastReadStoryId();
    } else {
      final bool shouldMarkNewComment =
          isMarkReadStoriesEnabled &&
          read<StoriesBloc>().state.readStoriesIds.contains(story.id);
      final ItemScreenArgs args = ItemScreenArgs(
        item: story,
        shouldMarkNewComment: shouldMarkNewComment,
      );

      read<ReminderCubit>().updateLastReadStoryId(story.id);

      if (isSplitViewEnabled) {
        read<SplitViewCubit>().updateItemScreenArgs(args);
      } else {
        this
          ..push(Paths.item.landing, extra: args)
          ..read<ReminderCubit>().onDismiss();
      }
    }

    if (story.url.isNotEmpty && isJobWithLink) {
      LinkUtils.launch(
        story.url,
        this,
        shouldUseReader: shouldUseReader,
        isOfflineReading: isOfflineReading,
      );
    }

    if (isMarkReadStoriesEnabled && storyMarkingMode.shouldDetectTapping) {
      read<StoriesBloc>().add(StoryRead(story: story));
    }
  }

  T? tryRead<T>() {
    try {
      return read<T>();
    } catch (_) {
      return null;
    }
  }

  void removeSnackBar() => ScaffoldMessenger.of(this).removeCurrentSnackBar();

  void showSnackBar({
    required String content,
    VoidCallback? action,
    Duration duration = AppDurations.fourSeconds,
    String? label,
    bool? persist,
    double? bottomPadding,
    bool isFloating = false,
  }) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          persist: persist,
          duration: duration,
          margin: bottomPadding == null
              ? null
              : EdgeInsets.only(bottom: bottomPadding, left: 10, right: 10),
          behavior: isFloating
              ? SnackBarBehavior.floating
              : SnackBarBehavior.fixed,
          backgroundColor: Theme.of(this).colorScheme.primary,
          content: Text(
            content,
            style: TextStyle(color: Theme.of(this).colorScheme.onPrimary),
          ),
          action: action != null && label != null
              ? SnackBarAction(label: label, onPressed: action)
              : null,
        ),
      );
  }

  void showErrorSnackBar([String? message, dynamic error]) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(this).colorScheme.errorContainer,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message ?? Constants.errorMessage,
              style: TextStyle(
                color: Theme.of(this).colorScheme.onErrorContainer,
              ),
            ),
            if (error != null)
              Text(
                error.toString(),
                style: TextStyle(
                  color: Theme.of(
                    this,
                  ).colorScheme.onErrorContainer.withAlpha(150),
                  fontSize: TextDimens.pt10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Rect? get rect {
    final RenderBox? box = findRenderObject() as RenderBox?;
    final Rect? rect = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    return rect;
  }

  static double _screenWidth = 0;
  static double _storyTileHeight = 0;
  static int _storyTileMaxLines = 4;
  static const double _screenWidthLowerBound = 430;
  static const double _screenWidthUpperBound = 850;
  static const double _picHeightLowerBound = 110;
  static const double _picHeightUpperBound = 128;
  static const double _smallPicHeight = 100;
  static const double _picHeightFactor = 0.3;

  double get storyTileHeight {
    final double screenWidth = min(
      MediaQuery.of(this).size.height,
      MediaQuery.of(this).size.width,
    );

    if (screenWidth == _screenWidth) {
      return _storyTileHeight;
    } else {
      _screenWidth = screenWidth;
    }

    final bool shouldShowSmallerPreviewPic =
        screenWidth > _screenWidthLowerBound &&
        screenWidth < _screenWidthUpperBound;
    final double height = shouldShowSmallerPreviewPic
        ? _smallPicHeight
        : (screenWidth * _picHeightFactor).clamp(
            _picHeightLowerBound,
            _picHeightUpperBound,
          );
    final int maxLines = height == _smallPicHeight ? 3 : 4;
    _storyTileMaxLines = maxLines;

    _storyTileHeight = height;
    return height;
  }

  int get storyTileMaxLines {
    return _storyTileMaxLines;
  }

  double get topPadding {
    return MediaQuery.of(this).padding.top + kToolbarHeight;
  }
}
