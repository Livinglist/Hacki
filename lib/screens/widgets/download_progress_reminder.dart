import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/styles/styles.dart';

class DownloadProgressReminder extends StatefulWidget {
  const DownloadProgressReminder({super.key});

  @override
  State<DownloadProgressReminder> createState() =>
      _DownloadProgressReminderState();
}

class _DownloadProgressReminderState extends State<DownloadProgressReminder>
    with SingleTickerProviderStateMixin, ItemActionMixin {
  late final AnimationController animationController;
  late final Animation<double> opacityAnimation;
  final Tween<double> opacity = Tween<double>(
    begin: 1,
    end: 0,
  );

  bool hasDismissed = false;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: AppDurations.twoSeconds,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            hasDismissed = false;
          });
        }
      });

    opacityAnimation = opacity.animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0,
          1,
          curve: Curves.ease,
        ),
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoriesBloc, StoriesState,
        (int, int, StoriesDownloadStatus)>(
      selector: (StoriesState state) {
        if (state.downloadStatus != StoriesDownloadStatus.downloading) {
          hasDismissed = false;
          animationController.forward();
        }
        return (
          state.storiesDownloaded,
          state.storiesToBeDownloaded,
          state.downloadStatus
        );
      },
      builder: (BuildContext context, (int, int, StoriesDownloadStatus) state) {
        final int storiesDownloaded = state.$1;
        final int storiesToBeDownloaded = state.$2;
        final StoriesDownloadStatus status = state.$3;
        final double progress = storiesDownloaded / storiesToBeDownloaded;
        final bool isVisible =
            !hasDismissed && status == StoriesDownloadStatus.downloading;
        return Visibility(
          visible: isVisible,
          child: AnimatedBuilder(
            animation: animationController,
            child: FadeIn(
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.all(
                  Radius.circular(
                    Dimens.pt4,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimens.pt12,
                        top: Dimens.pt10,
                        right: Dimens.pt10,
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Downloading All Stories ($storiesDownloaded/$storiesToBeDownloaded)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: TextDimens.pt12,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            child: Text(
                              'Dismiss',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: TextDimens.pt12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              animationController.forward();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: progress,
                    ),
                  ],
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: 1,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
