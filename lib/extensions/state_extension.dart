import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/screens/screens.dart' show ItemScreen, ItemScreenArgs;
import 'package:hacki/styles/styles.dart';

extension StateExtension on State {
  void showSnackBar({
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Palette.deepOrange,
        content: Text(content),
        action: action != null && label != null
            ? SnackBarAction(
                label: label,
                onPressed: action,
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void>? goToItemScreen({
    required ItemScreenArgs args,
    bool forceNewScreen = false,
  }) {
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    if (splitViewEnabled && !forceNewScreen) {
      context.read<SplitViewCubit>().updateItemScreenArgs(args);
    } else {
      return HackiApp.navigatorKey.currentState?.pushNamed(
        ItemScreen.routeName,
        arguments: args,
      );
    }

    return Future<void>.value();
  }
}
