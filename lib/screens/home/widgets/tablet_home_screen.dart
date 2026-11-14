import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/home/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart' hide Badge;

/// Keeps both panes mounted so folding the window preserves reading state.
class TabletHomeScreen extends StatelessWidget {
  const TabletHomeScreen({
    required this.homeScreen,
    this.splitViewEnabled = true,
    this.detailBuilder,
    super.key,
  });

  final Widget homeScreen;
  final bool splitViewEnabled;
  final Widget Function(BuildContext, ItemScreenArgs)? detailBuilder;

  static const double _dragPanelWidth = Dimens.pt2;
  static const double _dragDotHeight = Dimens.pt80;
  static const double _dragDotWidth = Dimens.pt40;
  static const double minimumPaneWidth = 280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double defaultWidth = min(width * 0.45, width >= 856 ? 428 : 345);
        return BlocBuilder<SplitViewCubit, SplitViewState>(
          builder: (BuildContext context, SplitViewState state) {
            final bool hasSelection = state.itemScreenArgs != null;
            final bool showCompactDetail =
                !splitViewEnabled &&
                hasSelection &&
                (state.showDetail || state.enabled);
            final bool showDetail = splitViewEnabled || showCompactDetail;
            final bool showFeed =
                !showCompactDetail && !(splitViewEnabled && state.expanded);
            final double maximumWidth = max(
              minimumPaneWidth,
              width - minimumPaneWidth - _dragPanelWidth,
            );
            final double submissionPanelWidth = splitViewEnabled
                ? (state.submissionPanelWidth ?? defaultWidth).clamp(
                    minimumPaneWidth,
                    maximumWidth,
                  )
                : width;
            final bool showDivider = splitViewEnabled && !state.expanded;

            void resizePane(DragUpdateDetails details) {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              final double localX = box
                  .globalToLocal(details.globalPosition)
                  .dx;
              context.read<SplitViewCubit>().updateSubmissionPanelWidth(
                localX.clamp(minimumPaneWidth, maximumWidth),
              );
            }

            return PopScope<void>(
              canPop:
                  !showCompactDetail && !(splitViewEnabled && state.expanded),
              onPopInvokedWithResult: (bool didPop, void result) {
                if (didPop) return;
                if (showCompactDetail) {
                  context.read<SplitViewCubit>().showStories();
                } else if (splitViewEnabled && state.expanded) {
                  context.read<SplitViewCubit>().zoom();
                }
              },
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: Dimens.zero,
                    top: Dimens.zero,
                    bottom: Dimens.zero,
                    width: submissionPanelWidth,
                    child: Offstage(
                      offstage: !showFeed,
                      child: TickerMode(
                        enabled: showFeed,
                        child: ExcludeFocus(
                          excluding: !showFeed,
                          child: homeScreen,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: Dimens.pt24,
                    bottom: Dimens.pt36,
                    height: Dimens.pt40,
                    width: max(0, submissionPanelWidth - Dimens.pt48),
                    child: Offstage(
                      offstage: !showFeed,
                      child: const HomeReminder(),
                    ),
                  ),
                  Positioned(
                    right: Dimens.zero,
                    top: Dimens.zero,
                    bottom: Dimens.zero,
                    left: splitViewEnabled && !state.expanded
                        ? submissionPanelWidth + _dragPanelWidth
                        : Dimens.zero,
                    child: Offstage(
                      offstage: !showDetail,
                      child: TickerMode(
                        enabled: showDetail,
                        child: ExcludeFocus(
                          excluding: !showDetail,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Offstage(
                                offstage: !showCompactDetail,
                                child: Material(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: MediaQuery.paddingOf(context).top,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        IconButton(
                                          tooltip: 'Back to stories',
                                          icon: const Icon(Icons.arrow_back),
                                          onPressed: context
                                              .read<SplitViewCubit>()
                                              .showStories,
                                        ),
                                        const Text('Stories'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: MediaQuery.removePadding(
                                  context: context,
                                  removeTop: showCompactDetail,
                                  child: _TabletStoryView(
                                    detailBuilder: detailBuilder,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showDivider) ...<Widget>[
                    Positioned(
                      left: submissionPanelWidth,
                      top: Dimens.zero,
                      bottom: Dimens.zero,
                      width: _dragPanelWidth,
                      child: GestureDetector(
                        onHorizontalDragUpdate: resizePane,
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          submissionPanelWidth +
                          _dragPanelWidth / 2 -
                          _dragDotWidth / 2,
                      top: (constraints.maxHeight - _dragDotHeight) / 2,
                      height: _dragDotHeight,
                      width: _dragDotWidth,
                      child: GestureDetector(
                        onHorizontalDragUpdate: resizePane,
                        child: Center(
                          child: CustomPaint(
                            painter: SpindlePainter(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.pt4,
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.gripLinesVertical,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  size: TextDimens.pt18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TabletStoryView extends StatefulWidget {
  const _TabletStoryView({this.detailBuilder});

  final Widget Function(BuildContext, ItemScreenArgs)? detailBuilder;

  @override
  State<_TabletStoryView> createState() => _TabletStoryViewState();
}

class _TabletStoryViewState extends State<_TabletStoryView> {
  ItemScreenArgs? _lastArgs;
  late Widget _selectedStory;

  @override
  void didUpdateWidget(_TabletStoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detailBuilder != widget.detailBuilder) {
      _lastArgs = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplitViewCubit, SplitViewState>(
      buildWhen: (SplitViewState previous, SplitViewState current) =>
          previous.itemScreenArgs != current.itemScreenArgs,
      builder: (BuildContext context, SplitViewState state) {
        final ItemScreenArgs? args = state.itemScreenArgs;
        if (args != null) {
          if (args != _lastArgs) {
            _lastArgs = args;
            _selectedStory = KeyedSubtree(
              key: ValueKey<ItemScreenArgs>(args),
              child:
                  widget.detailBuilder?.call(context, args) ??
                  ItemScreen.tablet(context, args),
            );
          }
          return _selectedStory;
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
