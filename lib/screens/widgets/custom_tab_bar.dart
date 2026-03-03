import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({
    required this.tabController,
    super.key,
  });

  final TabController tabController;

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late List<StoryType> tabs = context.read<TabCubit>().state.tabs;

  int currentIndex = 0;

  static const int _profileTabIndex = 5;

  @override
  void initState() {
    super.initState();

    widget.tabController.addListener(() {
      setState(() {
        currentIndex = widget.tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabCubit, TabState>(
      builder: (BuildContext context, TabState state) {
        final bool isHackerNewsThemeEnabled =
            context.read<PreferenceCubit>().state.isHackerNewsThemeEnabled;
        return TabBar(
          controller: widget.tabController,
          dividerHeight: 0,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicator: CircleTabIndicator(
            color: Theme.of(context).colorScheme.primary,
            radius: Dimens.pt2,
          ),
          splashFactory: NoSplash.splashFactory,
          indicatorPadding: const EdgeInsets.only(
            bottom: Dimens.pt8,
          ),
          onTap: (_) {
            HapticFeedbackUtil.selection();
          },
          tabAlignment: TabAlignment.center,
          tabs: <Widget>[
            for (int i = 0; i < state.tabs.length; i++)
              Tab(
                key: ValueKey<StoryType>(
                  state.tabs.elementAt(i),
                ),
                child: AnimatedDefaultTextStyle(
                  style: TextStyle(
                    fontFamily: context.read<PreferenceCubit>().state.font.name,
                    fontSize: () {
                      if (isHackerNewsThemeEnabled) {
                        return currentIndex == i
                            ? TextDimens.pt18
                            : TextDimens.pt12;
                      } else {
                        return currentIndex == i
                            ? TextDimens.pt12
                            : TextDimens.pt10;
                      }
                    }(),
                    color: () {
                      if (isHackerNewsThemeEnabled) {
                        return currentIndex == i
                            ? Palette.white
                            : Palette.black;
                      } else {
                        return currentIndex == i
                            ? Theme.of(context).colorScheme.primary
                            : Palette.grey;
                      }
                    }(),
                  ),
                  duration: AppDurations.ms200,
                  child: Text(
                    isHackerNewsThemeEnabled
                        ? state.tabs.elementAt(i).label.toLowerCase()
                        : state.tabs.elementAt(i).label,
                    key: ValueKey<String>(
                      '${state.tabs.elementAt(i).label}-${currentIndex == i}',
                    ),
                  ),
                ),
              ),
            Tab(
              child: CustomDescribedFeatureOverlay(
                onComplete: showOnboarding,
                tapTarget: Icon(
                  Icons.person,
                  size: TextDimens.pt16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                feature: DiscoverableFeature.login,
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  buildWhen: (
                    NotificationState previous,
                    NotificationState current,
                  ) =>
                      previous.unreadCommentsIds.length !=
                      current.unreadCommentsIds.length,
                  builder: (
                    BuildContext context,
                    NotificationState state,
                  ) {
                    return Badge(
                      showBadge: state.unreadCommentsIds.isNotEmpty,
                      badgeContent: Container(
                        height: Dimens.pt3,
                        width: Dimens.pt3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Palette.white,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: () {
                          if (isHackerNewsThemeEnabled) {
                            return currentIndex == _profileTabIndex
                                ? TextDimens.pt20
                                : TextDimens.pt14;
                          } else {
                            return currentIndex == _profileTabIndex
                                ? TextDimens.pt16
                                : TextDimens.pt12;
                          }
                        }(),
                        color: () {
                          if (isHackerNewsThemeEnabled) {
                            return currentIndex == _profileTabIndex
                                ? Palette.white
                                : Palette.black;
                          } else {
                            return currentIndex == _profileTabIndex
                                ? Theme.of(context).colorScheme.primary
                                : Palette.grey;
                          }
                        }(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showOnboarding() {
    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const OnboardingView(),
        fullscreenDialog: true,
      ),
    );
  }
}
