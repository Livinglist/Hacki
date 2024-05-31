import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:wakelock/wakelock.dart';

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
          Wakelock.disable();
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
                  Wakelock.enable();
                  context.read<StoriesBloc>().add(StoriesCancelDownload());
                }
              });
            } else {
              Connectivity()
                  .checkConnectivity()
                  .then((List<ConnectivityResult> res) {
                if (!res.contains(ConnectivityResult.none)) {
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
                      Wakelock.enable();
                      context.read<StoriesBloc>().add(
                            StoriesDownload(
                              includingWebPage: includeWebPage,
                            ),
                          );
                    }
                  });
                }
              });
            }
          },
        );
      },
    );
  }
}
