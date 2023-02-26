import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
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
    this.fromUserDialog = false,
  });

  /// If user gets to [SearchScreen] from user dialog on Tablet,
  /// we navigate to [ItemScreen] directly instead of injecting the
  /// item into [SplitViewCubit].
  final bool fromUserDialog;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RefreshController refreshController = RefreshController();
  final Debouncer debouncer = Debouncer(delay: const Duration(seconds: 1));

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
              resizeToAvoidBottomInset: false,
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.pt12,
                    ),
                    child: TextField(
                      cursorColor: Palette.orange,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Search Hacker News',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Palette.orange),
                        ),
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
                        const SizedBox(
                          width: Dimens.pt8,
                        ),
                        DateTimeRangeFilterChip(
                          filter: state.params.get<DateTimeRangeFilter>(),
                          onDateTimeRangeUpdated: context
                              .read<SearchCubit>()
                              .onDateTimeRangeUpdated,
                          onDateTimeRangeRemoved: context
                              .read<SearchCubit>()
                              .removeFilter<DateTimeRangeFilter>,
                        ),
                        const SizedBox(
                          width: Dimens.pt8,
                        ),
                        PostedByFilterChip(
                          filter: state.params.get<PostedByFilter>(),
                          onChanged:
                              context.read<SearchCubit>().onPostedByChanged,
                        ),
                        const SizedBox(
                          width: Dimens.pt8,
                        ),
                        CustomChip(
                          onSelected: (_) =>
                              context.read<SearchCubit>().onSortToggled(),
                          selected: state.params.sorted,
                          label: '''newest first''',
                        ),
                        const SizedBox(
                          width: Dimens.pt8,
                        ),
                        for (final CustomDateTimeRange range
                            in CustomDateTimeRange.values) ...<Widget>[
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
                            onSelected: (_) =>
                                context.read<SearchCubit>().onToggled(filter),
                            selected: context
                                    .read<SearchCubit>()
                                    .state
                                    .params
                                    .get<TypeTagFilter>() ==
                                filter,
                            label: filter.query,
                          ),
                        ],
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
                  Expanded(
                    child: SmartRefresher(
                      enablePullDown: false,
                      enablePullUp: true,
                      header: const WaterDropMaterialHeader(
                        backgroundColor: Palette.orange,
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
                      onRefresh: () {},
                      onLoading: () {
                        context.read<SearchCubit>().loadMore();
                      },
                      child: ListView(
                        children: <Widget>[
                          ...state.results
                              .map(
                                (Item e) => <Widget>[
                                  if (e is Story)
                                    FadeIn(
                                      child: StoryTile(
                                        showWebPreview:
                                            prefState.complexStoryTileEnabled,
                                        showMetadata: prefState.metadataEnabled,
                                        showUrl: prefState.urlEnabled,
                                        story: e,
                                        onTap: () => goToItemScreen(
                                          args: ItemScreenArgs(item: e),
                                          forceNewScreen: widget.fromUserDialog,
                                        ),
                                      ),
                                    )
                                  else if (e is Comment)
                                    FadeIn(
                                      child: CommentTile(
                                        myUsername: '',
                                        actionable: false,
                                        comment: e,
                                        fetchMode: FetchMode.eager,
                                        onTap: () => goToItemScreen(
                                          args: ItemScreenArgs(item: e),
                                          forceNewScreen: widget.fromUserDialog,
                                        ),
                                      ),
                                    ),
                                  if (!prefState.complexStoryTileEnabled)
                                    const Divider(
                                      height: Dimens.zero,
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
