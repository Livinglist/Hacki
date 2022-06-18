import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/widgets.dart';
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
              height: 24,
              width: 24,
              child: CustomCircularProgressIndicator(),
            );
          } else if (downloaded) {
            return const Icon(Icons.check_circle);
          }
          return const Icon(Icons.download);
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
            Connectivity().checkConnectivity().then((ConnectivityResult res) {
              if (res != ConnectivityResult.none) {
                Wakelock.enable();
                context.read<StoriesBloc>().add(StoriesDownload());
              }
            });
          },
        );
      },
    );
  }
}
