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
        return ListTile(
          title: Text(
            downloading ? 'Downloading All Stories...' : 'Download All Stories',
          ),
          subtitle: const Text(
            'download all latest stories that have at least one comment '
            "for offline reading. (web page won't be downloaded)",
          ),
          trailing: downloading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CustomCircularProgressIndicator(),
                )
              : const Icon(Icons.download),
          isThreeLine: true,
          onTap: () {
            Wakelock.enable();
            context.read<StoriesBloc>().add(StoriesDownload());
          },
        );
      },
    );
  }
}
