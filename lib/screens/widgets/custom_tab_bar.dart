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
            HapticFeedbackUtil.selection();
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
                  duration: Durations.ms200,
                  child: Text(
                    state.tabs.elementAt(i).label,
                    key: ValueKey<String>(
                      '${state.tabs.elementAt(i).label}-${currentIndex == i}',
                    ),
                  ),
                ),
              ),
            Tab(
              child: CustomDescribedFeatureOverlay(
                onComplete: showOnboarding,
                tapTarget: const Icon(
                  Icons.person,
                  size: TextDimens.pt16,
                  color: Palette.white,
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
