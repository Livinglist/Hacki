import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class StoriesListView extends StatefulWidget {
  const StoriesListView({
    super.key,
    required this.storyType,
    required this.header,
    required this.onStoryTapped,
  });

  final StoryType storyType;
  final Widget header;
  final ValueChanged<Story> onStoryTapped;

  @override
  State<StoriesListView> createState() => _StoriesListViewState();
}

class _StoriesListViewState extends State<StoriesListView> {
  final RefreshController refreshController = RefreshController();

  @override
  void dispose() {
    super.dispose();
    refreshController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoryType storyType = widget.storyType;
    final Widget header = widget.header;
    final ValueChanged<Story> onStoryTapped = widget.onStoryTapped;

    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.showComplexStoryTile != current.showComplexStoryTile ||
          previous.showMetadata != current.showMetadata,
      builder: (BuildContext context, PreferenceState preferenceState) {
        return BlocConsumer<StoriesBloc, StoriesState>(
          listenWhen: (StoriesState previous, StoriesState current) =>
              previous.statusByType[storyType] !=
              current.statusByType[storyType],
          listener: (BuildContext context, StoriesState state) {
            if (state.statusByType[storyType] == StoriesStatus.loaded) {
              refreshController
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
          },
          buildWhen: (StoriesState previous, StoriesState current) =>
              (current.currentPageByType[storyType] == 0 &&
                  previous.currentPageByType[storyType] == 0) ||
              (previous.storiesByType[storyType]!.length !=
                  current.storiesByType[storyType]!.length) ||
              (previous.readStoriesIds.length != current.readStoriesIds.length),
          builder: (BuildContext context, StoriesState state) {
            return ItemsListView<Story>(
              pinnable: true,
              showOfflineBanner: true,
              markReadStories:
                  context.read<PreferenceCubit>().state.markReadStories,
              showWebPreview: preferenceState.showComplexStoryTile,
              showMetadata: preferenceState.showMetadata,
              showUrl: preferenceState.showUrl,
              refreshController: refreshController,
              items: state.storiesByType[storyType]!,
              onRefresh: () {
                HapticFeedback.lightImpact();
                context
                    .read<StoriesBloc>()
                    .add(StoriesRefresh(type: storyType));
                context.read<PinCubit>().refresh();
              },
              onLoadMore: () {
                context
                    .read<StoriesBloc>()
                    .add(StoriesLoadMore(type: storyType));
              },
              onTap: onStoryTapped,
              onPinned: context.read<PinCubit>().pinStory,
              header: state.offlineReading ? null : header,
            );
          },
        );
      },
    );
  }
}
