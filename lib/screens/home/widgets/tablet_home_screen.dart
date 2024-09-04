import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TabletHomeScreen extends StatelessWidget {
  const TabletHomeScreen({
    required this.homeScreen,
    super.key,
  });

  final Widget homeScreen;
  static const double _dragPanelWidth = Dimens.pt6;
  static const double _dragDotHeight = 30;

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
              previous.expanded != current.expanded ||
              previous.submissionPanelWidth != current.submissionPanelWidth,
          builder: (BuildContext context, SplitViewState state) {
            final double submissionPanelWidth =
                state.submissionPanelWidth ?? homeScreenWidth;
            return Stack(
              children: <Widget>[
                AnimatedPositioned(
                  left: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  width: submissionPanelWidth,
                  duration: state.resizingAnimationDuration,
                  curve: Curves.elasticOut,
                  child: homeScreen,
                ),
                if (!context.read<ReminderCubit>().state.hasShown)
                  Positioned(
                    left: Dimens.pt24,
                    bottom: Dimens.pt36,
                    height: Dimens.pt40,
                    width: submissionPanelWidth - Dimens.pt24,
                    child: const CountdownReminder(),
                  )
                else
                  Positioned(
                    left: Dimens.pt24,
                    bottom: Dimens.pt36,
                    height: Dimens.pt40,
                    width: submissionPanelWidth - Dimens.pt24,
                    child: const DownloadProgressReminder(),
                  ),
                AnimatedPositioned(
                  right: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  left: state.expanded
                      ? Dimens.zero
                      : submissionPanelWidth + _dragPanelWidth,
                  duration: state.resizingAnimationDuration,
                  curve: Curves.elasticOut,
                  child: const _TabletStoryView(),
                ),
                Positioned(
                  left: submissionPanelWidth,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  width: _dragPanelWidth,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      context.read<SplitViewCubit>().updateSubmissionPanelWidth(
                            details.globalPosition.dx,
                          );
                    },
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.tertiary,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned(
                  left: submissionPanelWidth +
                      _dragPanelWidth / 2 -
                      _dragDotHeight / 2,
                  top:
                      (MediaQuery.of(context).size.height - _dragDotHeight) / 2,
                  height: _dragDotHeight,
                  width: _dragDotHeight,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      context.read<SplitViewCubit>().updateSubmissionPanelWidth(
                            details.globalPosition.dx,
                          );
                    },
                    child: Container(
                      width: _dragDotHeight,
                      height: _dragDotHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.gripLinesVertical,
                          color: Theme.of(context).colorScheme.onTertiary,
                          size: TextDimens.pt16,
                        ),
                      ),
                    ),
                  ),
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
          return ItemScreen.tablet(context, state.itemScreenArgs!);
        }

        return Material(
          child: ColoredBox(
            color: Theme.of(context).canvasColor,
            child: const Center(
              child: Text('Tap on story tile to view its comments.'),
            ),
          ),
        );
      },
    );
  }
}
