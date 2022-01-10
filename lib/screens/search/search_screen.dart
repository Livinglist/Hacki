import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/screens/story/story_screen.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/debouncer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final refreshController = RefreshController();
  final debouncer = Debouncer(delay: const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (context, prefState) {
        return BlocConsumer<SearchCubit, SearchState>(
          listener: (context, state) {
            if (state.status == SearchStatus.loaded) {
              refreshController.loadComplete();
            }
          },
          builder: (context, state) {
            return Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          debouncer.run(() {
                            context.read<SearchCubit>().search(val);
                          });
                        }
                      },
                    ),
                  ),
                  if (state.status == SearchStatus.loading) ...[
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
                        builder: (context, mode) {
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
                        children: [
                          ...state.results
                              .map((e) => [
                                    FadeIn(
                                      child: StoryTile(
                                          showWebPreview:
                                              prefState.showComplexStoryTile,
                                          story: e,
                                          onTap: () {
                                            HackiApp.navigatorKey.currentState!
                                                .pushNamed(
                                                    StoryScreen.routeName,
                                                    arguments: StoryScreenArgs(
                                                        story: e));
                                          }),
                                    ),
                                    if (!prefState.showComplexStoryTile)
                                      const Divider(
                                        height: 0,
                                      ),
                                  ])
                              .expand((e) => e)
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
