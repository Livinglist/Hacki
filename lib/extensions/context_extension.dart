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
}
