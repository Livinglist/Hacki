import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/screens/screens.dart' show StoryScreen, StoryScreenArgs;

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

  Future<void>? goToStoryScreen({required StoryScreenArgs args}) {
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    if (splitViewEnabled) {
      context.read<SplitViewCubit>().updateStoryScreenArgs(args);
    } else {
      return HackiApp.navigatorKey.currentState?.pushNamed(
        StoryScreen.routeName,
        arguments: args,
      );
    }

    return Future<void>.value();
  }
}
