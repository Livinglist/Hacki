import 'dart:async';

import 'package:badges/badges.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/circle_tab_indicator.dart';
import 'package:hacki/screens/widgets/onboarding_view.dart';
import 'package:hacki/styles/styles.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({
    super.key,
    required this.tabController,
  });

  final TabController tabController;

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late List<StoryType> tabs = context.read<TabCubit>().state.tabs;

  int currentIndex = 0;

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
        return TabBar(
          isScrollable: true,
          controller: widget.tabController,
          indicatorColor: Palette.orange,
          indicator: CircleTabIndicator(
            color: Palette.orange,
            radius: Dimens.pt2,
          ),
          indicatorPadding: const EdgeInsets.only(
            bottom: Dimens.pt8,
          ),
          onTap: (_) {
            HapticFeedback.selectionClick();
          },
          tabs: <Widget>[
            for (int i = 0; i < state.tabs.length; i++)
              Tab(
                key: ValueKey<StoryType>(
                  state.tabs.elementAt(i),
                ),
                child: AnimatedDefaultTextStyle(
                  style: TextStyle(
                    fontSize:
                        currentIndex == i ? TextDimens.pt14 : TextDimens.pt10,
                    color: currentIndex == i ? Palette.orange : Palette.grey,
                  ),
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    state.tabs.elementAt(i).label,
                    key: ValueKey<String>(
                      '${state.tabs.elementAt(i).label}-${currentIndex == i}',
                    ),
                  ),
                ),
              ),
            Tab(
              child: DescribedFeatureOverlay(
                onDismiss: () {
                  unawaited(HapticFeedback.lightImpact());
                  FeatureDiscovery.completeCurrentStep(context);
                  showOnboarding();
                  return Future<bool>.value(true);
                },
                onBackgroundTap: () {
                  unawaited(HapticFeedback.lightImpact());
                  FeatureDiscovery.completeCurrentStep(context);
                  showOnboarding();
                  return Future<bool>.value(true);
                },
                onComplete: () async {
                  unawaited(HapticFeedback.lightImpact());
                  showOnboarding();
                  return true;
                },
                overflowMode: OverflowMode.extendBackground,
                targetColor: Theme.of(context).primaryColor,
                tapTarget: const Icon(
                  Icons.person,
                  size: TextDimens.pt16,
                  color: Palette.white,
                ),
                featureId: Constants.featureLogIn,
                title: const Text('Log in for more'),
                description: const Text(
                  'Log in using your Hacker News account '
                  'to check out stories and comments you have '
                  'posted in the past, and get in-app '
                  'notification when there is new reply to '
                  'your comments or stories.',
                  style: TextStyle(fontSize: TextDimens.pt16),
                ),
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
                        size: currentIndex == 5
                            ? TextDimens.pt16
                            : TextDimens.pt12,
                        color:
                            currentIndex == 5 ? Palette.orange : Palette.grey,
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
