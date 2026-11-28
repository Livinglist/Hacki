import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/profile/widgets/centered_message_view.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({required this.onItemTap, super.key});

  final ValueChanged<Story> onItemTap;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (BuildContext context, HistoryState historyState) {
        if (historyState.stories.isEmpty) {
          if (historyState.status == Status.inProgress) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          return const Column(
            children: <Widget>[
              CenteredMessageView(
                content: 'Your latest 50 visited stories will show up here.',
              ),
            ],
          );
        }

        return BlocBuilder<PreferenceCubit, PreferenceState>(
          builder: (BuildContext context, PreferenceState prefState) {
            return ItemsListView<Story>(
              shouldShowWebPreviewOnStoryTile: prefState.isRichStoryTileEnabled,
              shouldShowMetadataOnStoryTile: prefState.isMetadataEnabled,
              shouldShowPreviewImage: prefState.isStoryTilePreviewImageEnabled,
              shouldShowFavicon: prefState.isFaviconEnabled,
              shouldShowUrl: prefState.isUrlEnabled,
              shouldUseMinimalTileForStory: true,
              shouldEnablePullDown: false,
              shouldEnablePullUp: false,
              refreshController: _refreshController,
              items: historyState.stories,
              onTap: widget.onItemTap,
            );
          },
        );
      },
    );
  }
}
