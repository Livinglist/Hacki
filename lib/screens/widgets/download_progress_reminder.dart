import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/services/dialog_proxy.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';

class DownloadProgressReminder extends StatefulWidget {
  const DownloadProgressReminder({this.isDockedAtBottom = false, super.key});

  final bool isDockedAtBottom;

  @override
  State<DownloadProgressReminder> createState() =>
      _DownloadProgressReminderState();
}

class _DownloadProgressReminderState extends State<DownloadProgressReminder>
    with SingleTickerProviderStateMixin, ItemActionMixin {
  late final AnimationController animationController;
  late final Animation<double> progressAnimation;
  final Tween<double> progress = Tween<double>(
    begin: 0,
    end: 1,
  );

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: AppDurations.threeSeconds,
    );
    progressAnimation = progress.animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0,
          1,
        ),
      ),
    );

    final StoriesBloc storiesBloc = context.read<StoriesBloc>();
    final int storiesDownloaded = storiesBloc.state.storiesDownloaded;
    final int storiesToBeDownloaded = storiesBloc.state.storiesToBeDownloaded;
    final double progressValue = storiesToBeDownloaded == 0
        ? 0
        : storiesDownloaded / storiesToBeDownloaded;
    animationController.value = progressValue;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoriesBloc, StoriesState,
        (int, int, StoriesDownloadStatus)>(
      selector: (StoriesState state) {
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
        final bool isVisible = status == StoriesDownloadStatus.downloading;

        return Visibility(
          visible: isVisible,
          child: GestureDetector(
            onTap: () {
              HapticFeedbackUtils.selection();
              DialogProxy.showAbortDownloadDialog(context);
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Hero(
                    tag: HeroTags.progressReminderHeroTag,
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
                          const Padding(
                            padding: EdgeInsets.only(
                              left: Dimens.pt12,
                              top: Dimens.pt10,
                              right: Dimens.pt10,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  ' ',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt12,
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: BlocListener<StoriesBloc, StoriesState>(
                                  listenWhen: (
                                    StoriesState previous,
                                    StoriesState current,
                                  ) =>
                                      (
                                        previous.storiesDownloaded,
                                        previous.storiesToBeDownloaded,
                                        previous.downloadStatus
                                      ) !=
                                      (
                                        current.storiesDownloaded,
                                        current.storiesToBeDownloaded,
                                        current.downloadStatus
                                      ),
                                  listener: (
                                    BuildContext context,
                                    StoriesState state,
                                  ) {
                                    final int storiesDownloaded =
                                        state.storiesDownloaded;
                                    final int storiesToBeDownloaded =
                                        state.storiesToBeDownloaded;
                                    final double progress =
                                        storiesToBeDownloaded == 0
                                            ? 0
                                            : storiesDownloaded /
                                                storiesToBeDownloaded;
                                    animationController.animateTo(progress);
                                  },
                                  child: AnimatedBuilder(
                                    animation: animationController,
                                    builder: (_, __) {
                                      return LinearProgressIndicator(
                                        value: progressAnimation.value,
                                        minHeight: Dimens.pt4,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withAlpha(140),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: Dimens.zero,
                  left: Dimens.zero,
                  right: Dimens.zero,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: Dimens.pt12,
                      top: Dimens.pt10,
                      right: Dimens.pt10,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (widget.isDockedAtBottom)
                          const SizedBox(
                            width: Dimens.pt28,
                          ),
                        Hero(
                          tag: HeroTags.progressReminderTextHeroTag,
                          child: Material(
                            color: Palette.transparent,
                            child: Text(
                              '''Downloading stories ($storiesDownloaded/$storiesToBeDownloaded)''',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: TextDimens.pt12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
