import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/search/widgets/widgets.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.isInBottomSheet = false,
  });

  /// If user is viewing [SearchScreen] in bottom sheet,
  /// we navigate to [ItemScreen] directly instead of injecting the
  /// item into [SplitViewCubit].
  final bool isInBottomSheet;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with ItemActionMixin {
  final RefreshController refreshController = RefreshController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final Debouncer debouncer = Debouncer(delay: AppDurations.oneSecond);

  static const Duration chipsAnimationDuration = AppDurations.ms300;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    refreshController.dispose();
    scrollController.dispose();
    focusNode
      ..unfocus()
      ..dispose();
    super.dispose();
  }

  void onScroll() => focusNode.unfocus();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (BuildContext context, PreferenceState prefState) {
        return BlocConsumer<SearchCubit, SearchState>(
          listener: (BuildContext context, SearchState state) {
            if (state.status == SearchStatus.loaded) {
              refreshController.loadComplete();
            }
          },
          builder: (BuildContext context, SearchState state) {
            return Scaffold(
              backgroundColor: Palette.transparent,
              resizeToAvoidBottomInset: false,
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SmartRefresher(
                      enablePullDown: false,
                      enablePullUp: true,
                      header: WaterDropMaterialHeader(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      footer: CustomFooter(
                        loadStyle: LoadStyle.ShowWhenLoading,
                        builder: (BuildContext context, LoadStatus? mode) {
                          const double height = 55;
                          late final Widget body;

                          if (mode == LoadStatus.loading) {
                            body = const CustomCircularProgressIndicator();
                          } else if (mode == LoadStatus.failed) {
                            body = const Text(
                              'loading failed.',
                            );
                          } else {
                            body = const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: height,
                            child: Center(child: body),
                          );
                        },
                      ),
                      controller: refreshController,
                      scrollController: scrollController,
                      onRefresh: () {},
                      onLoading: () {
                        context.read<SearchCubit>().loadMore();
                      },
                      child: ListView(
                        physics: state.results.isEmpty
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.pt12,
                                ),
                                child: TextField(
                                  controller: context
                                      .read<SearchCubit>()
                                      .textEditingController,
                                  focusNode: focusNode,
                                  cursorColor:
                                      Theme.of(context).colorScheme.primary,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    hintText: 'Search Hacker News',
                                  ),
                                  onChanged: (String val) {
                                    if (val.isNotEmpty) {
                                      debouncer.run(() {
                                        context.read<SearchCubit>().search(val);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: Dimens.pt6,
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    SizedBoxes.pt8,
                                    for (final CustomDateTimeRange range
                                        in CustomDateTimeRange
                                            .values) ...<Widget>[
                                      CustomRangeFilterChip(
                                        range: range,
                                        onTap: context
                                            .read<SearchCubit>()
                                            .onDateTimeRangeUpdated,
                                      ),
                                      const SizedBox(
                                        width: Dimens.pt8,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              AnimatedCrossFade(
                                duration: chipsAnimationDuration,
                                crossFadeState: state.showDateRangeShortcutChips
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: SizedBox.fromSize(),
                                secondChild: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: <Widget>[
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.dayBefore(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.dayAfter(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.weekBefore(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.weekAfter(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.monthBefore(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.monthAfter(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.yearBefore(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                          DateTimeShortcutChip.yearAfter(
                                            onDateTimeRangeUpdated: context
                                                .read<SearchCubit>()
                                                .onDateTimeRangeUpdated,
                                            startDate:
                                                state.dateFilter?.startTime,
                                            endDate: state.dateFilter?.endTime,
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    SizedBoxes.pt8,
                                    if (state.showDateRangeShortcutChips)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          CustomChip(
                                            onSelected: (_) => context
                                                .read<SearchCubit>()
                                                .removeFilter<
                                                    DateTimeRangeFilter>(),
                                            selected: false,
                                            label: '''reset''',
                                          ),
                                          const SizedBox(
                                            width: Dimens.pt8,
                                          ),
                                        ],
                                      ),
                                    DateTimeRangeFilterChip(
                                      filter: state.dateFilter,
                                      initialStartDate:
                                          state.dateFilter?.startTime,
                                      initialEndDate: state.dateFilter?.endTime,
                                      onDateTimeRangeUpdated: context
                                          .read<SearchCubit>()
                                          .onDateTimeRangeUpdated,
                                      onDateTimeRangeRemoved: context
                                          .read<SearchCubit>()
                                          .removeFilter<DateTimeRangeFilter>,
                                    ),
                                    SizedBoxes.pt8,
                                    PostedByFilterChip(
                                      filter:
                                          state.params.get<PostedByFilter>(),
                                      onChanged: context
                                          .read<SearchCubit>()
                                          .onPostedByChanged,
                                    ),
                                    SizedBoxes.pt8,
                                    PointsFilterChip(
                                      filter: state.params.get<PointsFilter>(),
                                      onChanged: context
                                          .read<SearchCubit>()
                                          .onPointsFilterChanged,
                                    ),
                                    SizedBoxes.pt8,
                                    NumberOfCommentsFilterChip(
                                      filter: state.params
                                          .get<CommentsNumberFilter>(),
                                      onChanged: context
                                          .read<SearchCubit>()
                                          .onNumberOfCommentsFilterChanged,
                                    ),
                                    SizedBoxes.pt8,
                                    CustomChip(
                                      onSelected: (_) => context
                                          .read<SearchCubit>()
                                          .onSortToggled(),
                                      selected: state.params.sorted,
                                      label: '''newest first''',
                                    ),
                                    SizedBoxes.pt8,
                                    CustomChip(
                                      onSelected: (_) => context
                                          .read<SearchCubit>()
                                          .onExactMatchToggled(),
                                      selected: state.params.exactMatch,
                                      label: '''exact match''',
                                    ),
                                    SizedBoxes.pt8,
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    for (final TypeTagFilter filter
                                        in TypeTagFilter.all) ...<Widget>[
                                      const SizedBox(
                                        width: Dimens.pt8,
                                      ),
                                      CustomChip(
                                        onSelected: (_) => context
                                            .read<SearchCubit>()
                                            .onToggled(filter),
                                        selected: context
                                                .read<SearchCubit>()
                                                .state
                                                .params
                                                .get<TypeTagFilter>() ==
                                            filter,
                                        label: filter.query,
                                      ),
                                    ],
                                    SizedBoxes.pt8,
                                  ],
                                ),
                              ),
                              if (state.status == SearchStatus.loading &&
                                  state.results.isEmpty) ...<Widget>[
                                const SizedBox(
                                  height: Dimens.pt100,
                                ),
                                const Center(
                                  child: CustomCircularProgressIndicator(),
                                ),
                              ],
                              if (state.status == SearchStatus.loaded &&
                                  state.results.isEmpty) ...<Widget>[
                                const SizedBox(
                                  height: Dimens.pt100,
                                ),
                                const Center(
                                  child: Text(
                                    'Nothing found...',
                                    style: TextStyle(
                                      color: Palette.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          ...state.results
                              .map(
                                (Item e) => <Widget>[
                                  if (e is Story)
                                    FadeIn(
                                      child: StoryTile(
                                        shouldShowWebPreview:
                                            prefState.isRichStoryTileEnabled,
                                        shouldShowMetadata:
                                            prefState.isMetadataEnabled,
                                        shouldShowUrl: prefState.isUrlEnabled,
                                        shouldShowFavicon:
                                            prefState.isFaviconEnabled,
                                        isImageLeftAligned:
                                            prefState.isPreviewImageLeftAligned,
                                        shouldShowPreviewImage: true,
                                        isExpandedTileEnabled: false,
                                        story: e,
                                        onTap: () => goToItemScreen(
                                          args: ItemScreenArgs(item: e),
                                          forceNewScreen:
                                              widget.isInBottomSheet,
                                        ),
                                      ),
                                    )
                                  else if (e is Comment)
                                    FadeIn(
                                      child: CommentTile(
                                        isActionable: false,
                                        isCollapsable: false,
                                        isSelectable: false,
                                        comment: e,
                                        fetchMode: FetchMode.eager,
                                        onTap: () => goToItemScreen(
                                          args: ItemScreenArgs(item: e),
                                          forceNewScreen:
                                              widget.isInBottomSheet,
                                        ),
                                      ),
                                    ),
                                  if (e is Story)
                                    Divider(
                                      height: prefState.isRichStoryTileEnabled
                                          ? Dimens.pt6
                                          : Dimens.zero,
                                    ),
                                ],
                              )
                              .expand((List<Widget> e) => e),
                          const SizedBox(
                            height: Dimens.pt40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
