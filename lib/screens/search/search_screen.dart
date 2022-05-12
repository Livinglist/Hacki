import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/story.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      cursorColor: Colors.orange,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Search Hacker News',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
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
                  if (state.status == SearchStatus.loading) ...<Widget>[
                    const SizedBox(
                      height: 100,
                    ),
                    const CustomCircularProgressIndicator(),
                  ],
                  Expanded(
                    child: SmartRefresher(
                      enablePullDown: false,
                      enablePullUp: true,
                      header: const WaterDropMaterialHeader(
                        backgroundColor: Colors.orange,
                      ),
                      footer: CustomFooter(
                        loadStyle: LoadStyle.ShowWhenLoading,
                        builder: (BuildContext context, LoadStatus? mode) {
                          Widget body;
                          if (mode == LoadStatus.idle) {
                            body = const Text('');
                          } else if (mode == LoadStatus.loading) {
                            body = const CustomCircularProgressIndicator();
                          } else if (mode == LoadStatus.failed) {
                            body = const Text(
                              'loading failed.',
                            );
                          } else if (mode == LoadStatus.canLoading) {
                            body = const Text(
                              'loading more.',
                            );
                          } else {
                            body = const Text('');
                          }
                          return SizedBox(
                            height: 55,
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
                                (Story e) => <Widget>[
                                  FadeIn(
                                    child: StoryTile(
                                      showWebPreview:
                                          prefState.showComplexStoryTile,
                                      story: e,
                                      onTap: () => goToStoryScreen(
                                        args: StoryScreenArgs(story: e),
                                      ),
                                    ),
                                  ),
                                  if (!prefState.showComplexStoryTile)
                                    const Divider(
                                      height: 0,
                                    ),
                                ],
                              )
                              .expand((List<Widget> e) => e)
                              .toList(),
                          const SizedBox(
                            height: 40,
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
