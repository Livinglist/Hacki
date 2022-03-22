import 'package:flutter/material.dart';

extension StateExtension on State {
  void showSnackBar({
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange,
        content: Text(content),
        action: action != null && label != null
            ? SnackBarAction(
                label: label,
                onPressed: action,
                textColor: Theme.of(context).textTheme.bodyText1?.color,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
