import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
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
        final double progress = storiesToBeDownloaded == 0
            ? 0
            : storiesDownloaded / storiesToBeDownloaded;
        final bool isVisible = status == StoriesDownloadStatus.downloading;
        return Visibility(
          visible: isVisible,
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
                          'Downloading all stories ($storiesDownloaded/$storiesToBeDownloaded)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: TextDimens.pt12,
                          ),
                        ),
                        const Spacer(),
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
        );
      },
    );
  }
}
