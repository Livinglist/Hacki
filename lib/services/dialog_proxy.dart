import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/stories/stories_bloc.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract class DialogProxy {
  static void showAbortDownloadDialog([BuildContext? context]) {
    context ??= navigatorKey.currentContext;
    if (context == null) return;
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Abort downloading?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ).then((bool? abortDownloading) {
      if (abortDownloading ?? false) {
        WakelockPlus.enable();

        if (context != null && context.mounted) {
          context.read<StoriesBloc>().add(StoriesCancelDownload());
        }
      }
    });
  }

  static void showDownloadCompletedDialog([BuildContext? context]) {
    context ??= navigatorKey.currentContext;
    if (context == null) return;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Download completed'),
        actions: <Widget>[
          TextButton(
            onPressed: context.pop,
            child: const Text('Noooice!'),
          ),
        ],
      ),
    );
  }
}
