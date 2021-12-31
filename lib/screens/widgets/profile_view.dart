import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/items_list_view.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

enum PageType { fav, history }

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin {
  final refreshControllerHistory = RefreshController();
  final refreshControllerFav = RefreshController();
  final scrollController = ScrollController(initialScrollOffset: 80);

  PageType _pageType = PageType.fav;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.username.isEmpty) {
          return Column(
            children: [
              const SizedBox(
                height: 120,
              ),
              ElevatedButton(
                onPressed: onLoginTapped,
                style: ElevatedButton.styleFrom(primary: Colors.orange),
                child: const Text('Log in'),
              )
            ],
          );
        }
        return BlocConsumer<HistoryCubit, HistoryState>(
          listener: (context, historyState) {
            if (historyState.status == HistoryStatus.loaded) {
              refreshControllerHistory
                ..refreshCompleted()
                ..loadComplete();
            }
          },
          builder: (context, historyState) {
            return BlocConsumer<FavCubit, FavState>(
              listener: (context, favState) {
                if (favState.status == FavStatus.loaded) {
                  refreshControllerFav
                    ..refreshCompleted()
                    ..loadComplete();
                }
              },
              builder: (context, favState) {
                return Stack(
                  children: [
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: _pageType != PageType.history,
                        child: ItemsListView<Item>(
                          refreshController: refreshControllerHistory,
                          items: historyState.submittedItems,
                          onRefresh: () {
                            context.read<HistoryCubit>().refresh();
                          },
                          onLoadMore: () {
                            context.read<HistoryCubit>().loadMore();
                          },
                          onTap: (item) {
                            if (item is Story) {
                              HackiApp.navigatorKey.currentState!.pushNamed(
                                  StoryScreen.routeName,
                                  arguments: StoryScreenArgs(story: item));
                            } else if (item is Comment) {
                              locator
                                  .get<StoriesRepository>()
                                  .fetchParentStory(id: item.parent.toString())
                                  .then((story) {
                                if (story != null && mounted) {
                                  HackiApp.navigatorKey.currentState!.pushNamed(
                                      StoryScreen.routeName,
                                      arguments: StoryScreenArgs(story: story));
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: _pageType != PageType.fav,
                        child: ItemsListView<Story>(
                          refreshController: refreshControllerFav,
                          items: favState.favStories,
                          onRefresh: () {
                            context.read<FavCubit>().refresh();
                          },
                          onLoadMore: () {
                            context.read<FavCubit>().loadMore();
                          },
                          onTap: (story) {
                            HackiApp.navigatorKey.currentState!.pushNamed(
                                StoryScreen.routeName,
                                arguments: StoryScreenArgs(story: story));
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: scrollController,
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            ActionChip(
                              label: const Text('About'),
                              elevation: 8,
                              onPressed: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Hacki',
                                  applicationVersion: '0.0.1',
                                  applicationIcon: Image.asset(
                                    'images/hacki_icon.png',
                                    height: 96,
                                    width: 96,
                                  ),
                                  applicationLegalese: '2022 Jiaqi Feng',
                                  children: [
                                    TextButton(
                                      onPressed: () => LinkUtil.launchUrl(
                                          'https://github.com/Livinglist/Hacki'),
                                      child: const Text('Source Code'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            ActionChip(
                              label: const Text('Log out'),
                              elevation: 8,
                              onPressed: onLogoutTapped,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            FilterChip(
                              label: const Text(
                                'Favorite',
                              ),
                              elevation: 8,
                              selected: _pageType == PageType.fav,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _pageType = PageType.fav;
                                  });
                                }
                              },
                              selectedColor: Colors.orange,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            FilterChip(
                              label: const Text(
                                'Submitted',
                              ),
                              elevation: 8,
                              selected: _pageType == PageType.history,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _pageType = PageType.history;
                                  });
                                }
                              },
                              selectedColor: Colors.orange,
                            ),
                            const SizedBox(
                              width: 130,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void onLoginTapped() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged in successfully!'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          builder: (context, state) {
            return SimpleDialog(
              children: [
                if (state.status == AuthStatus.loading)
                  const SizedBox(
                    height: 36,
                    width: 36,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                      ),
                    ),
                  )
                else if (!state.isLoggedIn) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: TextField(
                      controller: usernameController,
                      cursorColor: Colors.orange,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: TextField(
                      controller: passwordController,
                      cursorColor: Colors.orange,
                      obscureText: true,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  if (state.status == AuthStatus.failure)
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 18,
                      ),
                      child: Text(
                        'Something went wrong...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                    ),
                    child: ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final username = usernameController.text;
                            final password = passwordController.text;
                            if (username.isNotEmpty && password.isNotEmpty) {
                              context.read<AuthBloc>().add(AuthLogin(
                                    username: username,
                                    password: password,
                                  ));
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.orange),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void onLogoutTapped() {
    final authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          children: [
            ...[
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Text(
                  'Log out as ${authBloc.state.username}?',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                ),
                child: ButtonBar(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthLogout());
                        context.read<FavCubit>().reset();
                        context.read<HistoryCubit>().reset();
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.orange),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
