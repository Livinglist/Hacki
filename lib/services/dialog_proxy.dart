import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/stories/stories_bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/config/router.dart';
import 'package:hacki/cubits/search/search_cubit.dart';
import 'package:hacki/models/item/item.dart';
import 'package:hacki/screens/item/widgets/time_machine_dialog.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract final class DialogProxy {
  static void showSettingsBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height - Dimens.pt120,
          child: const Column(
            children: <Widget>[
              Expanded(
                child: SettingsView(),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showHackerNewsSearchBottomSheet(
    BuildContext context,
    String text,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return BlocProvider<SearchCubit>(
          create: (_) => SearchCubit()..search(text),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - Dimens.pt120,
            child: const Column(
              children: <Widget>[
                Expanded(
                  child: SearchScreen(
                    isInBottomSheet: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showTimeMachineDialog(
    BuildContext context, {
    required Item rootItem,
    required Comment comment,
  }) {
    final Size size = MediaQuery.of(context).size;
    final DeviceScreenType deviceType = getDeviceType(size);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height - Dimens.pt120,
          child: Column(
            children: <Widget>[
              Expanded(
                child: TimeMachineDialog(
                  comment: comment,
                  rootItem: rootItem,
                  deviceType: deviceType,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
    HapticFeedbackUtils.success();
    context ??= navigatorKey.currentContext;
    if (context == null) return;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Download completed'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              context.pop();
              locator.get<AppReviewService>().requestReview();
            },
            child: const Text('Noooice!'),
          ),
        ],
      ),
    );
  }
}
