import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TabletHomeScreen extends StatelessWidget {
  const TabletHomeScreen({
    super.key,
    required this.homeScreen,
  });

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (BuildContext context, SizingInformation sizeInfo) {
        context.read<SplitViewCubit>().enableSplitView();
        double homeScreenWidth = 428;

        if (sizeInfo.screenSize.width < homeScreenWidth * 2) {
          homeScreenWidth = 345;
        }

        return BlocBuilder<SplitViewCubit, SplitViewState>(
          buildWhen: (SplitViewState previous, SplitViewState current) =>
              previous.expanded != current.expanded,
          builder: (BuildContext context, SplitViewState state) {
            return Stack(
              children: <Widget>[
                AnimatedPositioned(
                  left: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  width: homeScreenWidth,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: homeScreen,
                ),
                Positioned(
                  left: Dimens.pt24,
                  bottom: Dimens.pt36,
                  height: Dimens.pt40,
                  width: homeScreenWidth - Dimens.pt24,
                  child: const CountdownReminder(),
                ),
                AnimatedPositioned(
                  right: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  left: state.expanded ? Dimens.zero : homeScreenWidth,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: const _TabletStoryView(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TabletStoryView extends StatelessWidget {
  const _TabletStoryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplitViewCubit, SplitViewState>(
      buildWhen: (SplitViewState previous, SplitViewState current) =>
          previous.itemScreenArgs != current.itemScreenArgs,
      builder: (BuildContext context, SplitViewState state) {
        if (state.itemScreenArgs != null) {
          return ItemScreen.build(context, state.itemScreenArgs!);
        }

        return Material(
          child: ColoredBox(
            color: Theme.of(context).canvasColor,
            child: const Center(
              child: Text('Tap on story tile to view comments.'),
            ),
          ),
        );
      },
    );
  }
}
