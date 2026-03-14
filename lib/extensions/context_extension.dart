import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/styles/dimens.dart';

extension ContextExtension on BuildContext {
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
    String? label,
  }) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(this).colorScheme.inverseSurface,
          content: Text(
            content,
            style: TextStyle(
              color: Theme.of(this).colorScheme.onInverseSurface,
            ),
          ),
          action: action != null && label != null
              ? SnackBarAction(
                  label: label,
                  onPressed: action,
                  textColor: Theme.of(this).colorScheme.onInverseSurface,
                )
              : null,
        ),
      );
  }

  void showErrorSnackBar([
    String? message,
    dynamic error,
  ]) {
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
                  color: Theme.of(this).colorScheme.onErrorContainer.withAlpha(
                        150,
                      ),
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
    final Rect? rect =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
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
    final double screenWidth =
        min(MediaQuery.of(this).size.height, MediaQuery.of(this).size.width);

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
        : (screenWidth * _picHeightFactor)
            .clamp(_picHeightLowerBound, _picHeightUpperBound);
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
