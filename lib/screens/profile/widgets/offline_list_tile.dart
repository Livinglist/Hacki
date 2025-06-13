import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class OfflineListTile extends StatelessWidget {
  const OfflineListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoriesBloc, StoriesState>(
      listenWhen: (StoriesState previous, StoriesState current) =>
          previous.downloadStatus != current.downloadStatus,
      listener: (BuildContext context, StoriesState state) {
        if (state.downloadStatus == StoriesDownloadStatus.failure ||
            state.downloadStatus == StoriesDownloadStatus.finished) {
          WakelockPlus.disable();
        }
      },
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.downloadStatus != current.downloadStatus ||
          previous.storiesDownloaded != current.storiesDownloaded ||
          previous.storiesToBeDownloaded != current.storiesToBeDownloaded,
      builder: (BuildContext context, StoriesState state) {
        final bool downloading =
            state.downloadStatus == StoriesDownloadStatus.downloading;
        final bool downloaded =
            state.downloadStatus == StoriesDownloadStatus.finished;

        final Widget trailingWidget = () {
          if (downloading) {
            return const SizedBox(
              height: Dimens.pt24,
              width: Dimens.pt24,
              child: CustomCircularProgressIndicator(),
            );
          } else if (downloaded) {
            return Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            );
          }
          return Icon(
            Icons.download,
            color: Theme.of(context).colorScheme.primary,
          );
        }();

        return ListTile(
          title: Text(
            downloading
                ? '''Downloading All Stories (${state.storiesDownloaded}/${state.storiesToBeDownloaded})'''
                : 'Download All Stories',
          ),
          subtitle: const Text(
            'download all latest stories that have at least one comment '
            'for offline reading. (Please keep Hacki in foreground while '
            'downloading.)',
          ),
          trailing: trailingWidget,
          isThreeLine: true,
          onTap: () {
            if (state.downloadStatus == StoriesDownloadStatus.downloading) {
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

                  if (context.mounted) {
                    context.read<StoriesBloc>().add(StoriesCancelDownload());
                  }
                }
              });
            } else {
              Connectivity()
                  .checkConnectivity()
                  .then((List<ConnectivityResult> res) {
                if (!res.contains(ConnectivityResult.none) && context.mounted) {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return BlocSelector<StoriesBloc, StoriesState,
                          MaxOfflineStoriesCount?>(
                        selector: (StoriesState state) =>
                            state.maxOfflineStoriesCount,
                        builder: (
                          BuildContext c,
                          MaxOfflineStoriesCount? maxStories,
                        ) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBoxes.pt12,
                                const Text(
                                  'How many stories do you want to download?',
                                ),
                                for (final MaxOfflineStoriesCount count
                                    in MaxOfflineStoriesCount.values)
                                  RadioListTile<MaxOfflineStoriesCount>(
                                    value: count,
                                    groupValue: state.maxOfflineStoriesCount,
                                    title: Text(count.label),
                                    onChanged: (MaxOfflineStoriesCount? val) {
                                      HapticFeedbackUtil.selection();

                                      if (val != null) {
                                        context.pop();
                                        final StoriesBloc storiesBloc =
                                            context.read<StoriesBloc>()
                                              ..add(
                                                UpdateMaxOfflineStoriesCount(
                                                  count: val,
                                                ),
                                              );
                                        showConfirmationDialog(
                                          context,
                                          storiesBloc,
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              });
            }
          },
        );
      },
    );
  }

  void showConfirmationDialog(BuildContext context, StoriesBloc storiesBloc) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Download web pages as well?'),
        content: const Text('It will take longer time.'),
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
    ).then((bool? includeWebPage) {
      if (includeWebPage != null) {
        WakelockPlus.enable();

        storiesBloc.add(
          StoriesDownload(
            includingWebPage: includeWebPage,
          ),
        );
      }
    });
  }
}
