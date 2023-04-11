import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/styles/styles.dart';

extension ContextExtension on BuildContext {
  T? tryRead<T>() {
    try {
      return read<T>();
    } catch (_) {
      return null;
    }
  }

  void showSnackBar({
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: Palette.deepOrange,
        content: Text(content),
        action: action != null && label != null
            ? SnackBarAction(
                label: label,
                onPressed: action,
                textColor: Theme.of(this).textTheme.bodyLarge?.color,
              )
            : null,
      ),
    );
  }

  void showErrorSnackBar() => showSnackBar(
        content: Constants.errorMessage,
      );

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

    final bool showSmallerPreviewPic = screenWidth > _screenWidthLowerBound &&
        screenWidth < _screenWidthUpperBound;
    final double height = showSmallerPreviewPic
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
}
