import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class StoriesListView extends StatelessWidget {
  const StoriesListView({
    Key? key,
    required this.storyType,
    required this.header,
    required this.refreshController,
  }) : super(key: key);

  final StoryType storyType;
  final Widget header;
  final RefreshController refreshController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (previous, current) =>
          previous.showComplexStoryTile != current.showComplexStoryTile,
      builder: (context, preferenceState) {
        return BlocBuilder<StoriesBloc, StoriesState>(
          buildWhen: (previous, current) =>
              (current.currentPageByType[storyType] == 0 &&
                  previous.currentPageByType[storyType] == 0) ||
              previous.currentPageByType[storyType] !=
                      current.currentPageByType[storyType] &&
                  previous.storiesByType[storyType] !=
                      current.storiesByType[storyType],
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
              onTap: (story) => onStoryTapped(story, context),
              onPinned: context.read<PinCubit>().pinStory,
              header: header,
            );
          },
        );
      },
    );
  }

  void onStoryTapped(Story story, BuildContext context) {
    final cacheService = locator.get<CacheService>();
    final showWebFirst = context.read<PreferenceCubit>().state.showWebFirst;
    final useReader = context.read<PreferenceCubit>().state.useReader;
    final offlineReading = context.read<StoriesBloc>().state.offlineReading;
    final firstTimeReading = cacheService.isFirstTimeReading(story.id);

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final isJobWithLink = story.type == 'job' && story.url.isNotEmpty;

    if (!isJobWithLink) {
      HackiApp.navigatorKey.currentState!.pushNamed(StoryScreen.routeName,
          arguments: StoryScreenArgs(story: story));
    }

    if (!offlineReading &&
        (isJobWithLink || (showWebFirst && firstTimeReading))) {
      LinkUtil.launchUrl(story.url, useReader: useReader);
      cacheService.store(story.id);
    }

    context.read<CacheCubit>().markStoryAsRead(story.id);
  }
}
