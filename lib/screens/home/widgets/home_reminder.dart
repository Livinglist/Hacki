import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Gives active downloads priority over the last-read-story reminder.
class HomeReminder extends StatelessWidget {
  const HomeReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final bool downloading = context.select<StoriesBloc, bool>(
      (StoriesBloc bloc) =>
          bloc.state.downloadStatus == StoriesDownloadStatus.downloading,
    );
    return Stack(
      children: <Widget>[
        // Preserve the reminder's timer and any pending navigation.
        Offstage(offstage: downloading, child: const CountdownReminder()),
        if (downloading) const DownloadProgressReminder(),
      ],
    );
  }
}
