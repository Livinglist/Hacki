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
}
