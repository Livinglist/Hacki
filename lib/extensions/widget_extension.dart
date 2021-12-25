import 'package:flutter/material.dart';

extension WidgetModifier on Widget {
  Widget padding([EdgeInsetsGeometry value = const EdgeInsets.all(12)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }
}
