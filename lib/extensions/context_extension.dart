import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension TryReadContext on BuildContext {
  T? tryRead<T>() {
    try {
      return read<T>();
    } catch (_) {
      return null;
    }
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
  static const double _screenWidthLowerBound = 428,
      _screenWidthUpperBound = 850,
      _picHeightLowerBound = 110,
      _picHeightUpperBound = 128,
      _smallPicHeight = 100,
      _picHeightFactor = 0.3;

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
