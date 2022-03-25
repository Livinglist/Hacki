import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:wakelock/wakelock.dart';

class OfflineListTile extends StatelessWidget {
  const OfflineListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoriesBloc, StoriesState>(
      listenWhen: (previous, current) =>
          previous.downloadStatus != current.downloadStatus,
      listener: (context, state) {
        if (state.downloadStatus == StoriesDownloadStatus.failure) {
          Wakelock.disable();
        }
      },
      buildWhen: (previous, current) =>
          previous.downloadStatus != current.downloadStatus,
      builder: (context, state) {
        final downloading =
            state.downloadStatus == StoriesDownloadStatus.downloading;
        final downloaded =
            state.downloadStatus == StoriesDownloadStatus.finished;

        final trailingWidget = () {
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
            downloading ? 'Downloading All Stories...' : 'Download All Stories',
          ),
          subtitle: const Text(
            'download all latest stories that have at least one comment '
            "for offline reading. (web page won't be downloaded)",
          ),
          trailing: trailingWidget,
          isThreeLine: true,
          onTap: () {
            Connectivity().checkConnectivity().then((res) {
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
