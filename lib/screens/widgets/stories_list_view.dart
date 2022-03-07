import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class StoriesListView extends StatelessWidget {
  const StoriesListView({
    Key? key,
    required this.storyType,
    required this.header,
    required this.onStoryTapped,
    required this.refreshController,
  }) : super(key: key);

  final StoryType storyType;
  final Widget header;
  final ValueChanged<Story> onStoryTapped;
  final RefreshController refreshController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (previous, current) =>
          previous.showComplexStoryTile != current.showComplexStoryTile,
      builder: (context, preferenceState) {
        return BlocConsumer<StoriesBloc, StoriesState>(
          listenWhen: (previous, current) =>
              previous.statusByType[storyType] !=
              current.statusByType[storyType],
          listener: (context, state) {
            if (state.statusByType[storyType] == StoriesStatus.loaded) {
              refreshController
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
          },
          buildWhen: (previous, current) =>
              (current.currentPageByType[storyType] == 0 &&
                  previous.currentPageByType[storyType] == 0) ||
              (previous.storiesByType[storyType]!.length !=
                  current.storiesByType[storyType]!.length),
          builder: (context, state) {
            return ItemsListView<Story>(
              pinnable: true,
              markReadStories:
                  context.read<PreferenceCubit>().state.markReadStories,
              showWebPreview: preferenceState.showComplexStoryTile,
              refreshController: refreshController,
              items: state.storiesByType[storyType]!,
              onRefresh: () {
                HapticFeedback.lightImpact();
                context
                    .read<StoriesBloc>()
                    .add(StoriesRefresh(type: storyType));
              },
              onLoadMore: () {
                context
                    .read<StoriesBloc>()
                    .add(StoriesLoadMore(type: storyType));
              },
              onTap: onStoryTapped,
              onPinned: context.read<PinCubit>().pinStory,
              header: header,
            );
          },
        );
      },
    );
  }
}
