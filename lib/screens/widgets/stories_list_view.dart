import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:visibility_detector/visibility_detector.dart';

class StoriesListView extends StatefulWidget {
  const StoriesListView({
    required this.storyType,
    required this.header,
    required this.onStoryTapped,
    super.key,
  });

  final StoryType storyType;
  final Widget header;
  final ValueChanged<Story> onStoryTapped;

  @override
  State<StoriesListView> createState() => _StoriesListViewState();
}

class _StoriesListViewState extends State<StoriesListView>
    with ItemActionMixin {
  final RefreshController refreshController = RefreshController();
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    refreshController.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StoryType storyType = widget.storyType;
    final Widget header = widget.header;
    final ValueChanged<Story> onStoryTapped = widget.onStoryTapped;

    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.complexStoryTileEnabled != current.complexStoryTileEnabled ||
          previous.metadataEnabled != current.metadataEnabled ||
          previous.paginationEnabled != current.paginationEnabled,
      builder: (BuildContext context, PreferenceState preferenceState) {
        return BlocConsumer<StoriesBloc, StoriesState>(
          listenWhen: (StoriesState previous, StoriesState current) =>
              previous.statusByType[storyType] !=
              current.statusByType[storyType],
          listener: (BuildContext context, StoriesState state) {
            if (state.statusByType[storyType] == Status.success) {
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
              showOfflineBanner: true,
              markReadStories: preferenceState.markReadStoriesEnabled,
              showWebPreviewOnStoryTile:
                  preferenceState.complexStoryTileEnabled,
              showMetadataOnStoryTile: preferenceState.metadataEnabled,
              showUrl: preferenceState.urlEnabled,
              refreshController: refreshController,
              scrollController: scrollController,
              items: state.storiesByType[storyType]!,
              onRefresh: () {
                HapticFeedbackUtil.light();
                context
                    .read<StoriesBloc>()
                    .add(StoriesRefresh(type: storyType));
                context.read<PinCubit>().refresh();
              },
              onLoadMore: () {
                if (preferenceState.paginationEnabled) {
                  refreshController
                    ..refreshCompleted(resetFooterState: true)
                    ..loadComplete();
                } else {
                  loadMoreStories();
                }
              },
              onTap: onStoryTapped,
              onPinned: context.read<PinCubit>().pinStory,
              header: state.isOfflineReading ? null : header,
              loadStyle: LoadStyle.HideAlways,
              footer: preferenceState.paginationEnabled &&
                      state.statusByType[widget.storyType] == Status.success &&
                      (state.storiesByType[widget.storyType]?.length ?? 0) <
                          (state.storyIdsByType[widget.storyType]?.length ?? 0)
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: Dimens.pt48,
                        right: Dimens.pt48,
                        top: Dimens.pt36,
                        bottom: Dimens.pt12,
                      ),
                      child: OutlinedButton(
                        onPressed: loadMoreStories,
                        style: ButtonStyle(
                          foregroundColor: MaterialStateColor.resolveWith(
                            (_) => Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        child: Text(
                          '''Load Page ${(state.currentPageByType[widget.storyType] ?? 0) + 2}''',
                        ),
                      ),
                    )
                  : null,
              onMoreTapped: onMoreTapped,
              itemBuilder: (Widget child, Story story) {
                return Slidable(
                  enabled: !preferenceState.swipeGestureEnabled,
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: <Widget>[
                      SlidableAction(
                        onPressed: (_) {
                          HapticFeedbackUtil.light();
                          context.read<PinCubit>().pinStory(story);
                        },
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        icon: preferenceState.complexStoryTileEnabled
                            ? Icons.push_pin_outlined
                            : null,
                        label: preferenceState.complexStoryTileEnabled
                            ? null
                            : 'Pin to top',
                      ),
                      SlidableAction(
                        onPressed: (_) => onMoreTapped(story, context.rect),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        icon: preferenceState.complexStoryTileEnabled
                            ? Icons.more_horiz
                            : null,
                        label: preferenceState.complexStoryTileEnabled
                            ? null
                            : 'More',
                      ),
                    ],
                  ),
                  child: OptionalWrapper(
                    enabled: context
                            .read<PreferenceCubit>()
                            .state
                            .storyMarkingMode
                            .shouldDetectScrollingPast &&
                        !context.read<StoriesBloc>().hasRead(story),
                    wrapper: (Widget child) => VisibilityDetector(
                      key: ValueKey<int>(story.id),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (info.visibleFraction == 0 &&
                            mounted &&
                            scrollController.position.userScrollDirection ==
                                ScrollDirection.reverse &&
                            !state.readStoriesIds.contains(story.id)) {
                          context
                              .read<StoriesBloc>()
                              .add(StoryRead(story: story));
                        }
                      },
                      child: child,
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void loadMoreStories() =>
      context.read<StoriesBloc>().add(StoriesLoadMore(type: widget.storyType));
}
