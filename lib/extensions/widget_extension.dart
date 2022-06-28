import 'package:flutter/material.dart';

extension WidgetModifier on Widget {
  Widget padded([EdgeInsetsGeometry value = const EdgeInsets.all(12)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }
}
