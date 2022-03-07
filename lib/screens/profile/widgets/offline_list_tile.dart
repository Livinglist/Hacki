import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/custom_circular_progress_indicator.dart';

class OfflineListTile extends StatelessWidget {
  const OfflineListTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
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
            'download latest stories and comments '
            "for offline reading. (web page won't be "
            'downloaded)',
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
            context.read<StoriesBloc>().add(StoriesDownload());
          },
        );
      },
    );
  }
}
