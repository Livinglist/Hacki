import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

/// The buttons for skipping to the previous or next root comment. They also
/// hold the back and forward buttons unless the user has chosen to keep
/// those separate, in which case [FloatingHistoryButtons] shows them.
class FloatingSkipButtons extends StatelessWidget {
  const FloatingSkipButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWebViewBottomSheetEnabled = context
        .select<PreferenceCubit, bool>(
          (PreferenceCubit cubit) => cubit.state.isWebViewBottomSheetEnabled,
        );
    final bool areHistoryButtonsCombined = context
        .select<PreferenceCubit, bool>(
          (PreferenceCubit cubit) => cubit.state.areHistoryButtonsCombined,
        );
    final Offset offset = context.select<ThreadNavigationButtonCubit, Offset>(
      (ThreadNavigationButtonCubit cubit) =>
          Offset(cubit.state.dx, cubit.state.dy),
    );

    return _DraggableButtonGroup(
      offset: offset,
      onOffsetChanged: context
          .read<ThreadNavigationButtonCubit>()
          .updateButtonPosition,
      builder: (BuildContext context, bool isDragging) {
        return <Widget>[
          if (areHistoryButtonsCombined) ...<Widget>[
            _BackButton(isDragging: isDragging),
            SizedBoxes.pt12,
          ],
          CustomDescribedFeatureOverlay(
            feature: DiscoverableFeature.jumpUpButton,
            contentLocation: ContentLocation.above,
            tapTarget: Icon(
              Icons.keyboard_arrow_up,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            child: TapDownWrapper(
              child: AnimatedScale(
                scale: isDragging ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: InkWell(
                  enableFeedback: false,
                  onLongPress: () {
                    HapticFeedbackUtils.light();
                    context.read<CommentsCubit>().scrollTo(
                      index: 0,
                      recordNavigation: true,
                    );
                  },
                  child: FloatingActionButton(
                    enableFeedback: false,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withAlpha(200),

                    /// Randomly generated string as heroTag to
                    /// prevent default [FloatingActionButton]
                    /// animation.
                    heroTag: UniqueKey().hashCode,
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      context.read<CommentsCubit>().scrollToPreviousRoot();
                    },
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBoxes.pt12,
          CustomDescribedFeatureOverlay(
            feature: DiscoverableFeature.jumpDownButton,
            tapTarget: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            contentLocation: ContentLocation.above,
            child: TapDownWrapper(
              child: AnimatedScale(
                scale: isDragging ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: InkWell(
                  enableFeedback: false,
                  onLongPress: () {
                    HapticFeedbackUtils.light();
                    final CommentsCubit cubit = context.read<CommentsCubit>();
                    cubit.scrollTo(
                      index: cubit.state.comments.length,
                      recordNavigation: true,
                    );
                  },
                  child: FloatingActionButton(
                    enableFeedback: false,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withAlpha(200),

                    /// Same as above.
                    heroTag: UniqueKey().hashCode,
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      context.read<CommentsCubit>().scrollToNextRoot(
                        onError: () => context.showSnackBar(
                          content: '''No more root level comment below.''',
                        ),
                      );
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (areHistoryButtonsCombined) ...<Widget>[
            SizedBoxes.pt12,
            _ForwardButton(isDragging: isDragging),
          ],
          if (isWebViewBottomSheetEnabled) const SizedBox(height: Dimens.pt64),
        ];
      },
    );
  }
}

/// The back and forward buttons as their own group, shown when the user has
/// chosen not to combine them with [FloatingSkipButtons]. The group can be
/// dragged around and remembers where it was left.
class FloatingHistoryButtons extends StatelessWidget {
  const FloatingHistoryButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final bool areHistoryButtonsSeparate = context
        .select<PreferenceCubit, bool>(
          (PreferenceCubit cubit) => cubit.state.areHistoryButtonsSeparate,
        );
    if (!areHistoryButtonsSeparate) {
      return const SizedBox.shrink();
    }

    final bool isWebViewBottomSheetEnabled = context
        .select<PreferenceCubit, bool>(
          (PreferenceCubit cubit) => cubit.state.isWebViewBottomSheetEnabled,
        );
    final Offset offset = context.select<ThreadNavigationButtonCubit, Offset>(
      (ThreadNavigationButtonCubit cubit) =>
          Offset(cubit.state.historyDx, cubit.state.historyDy),
    );

    return _DraggableButtonGroup(
      offset: offset,
      onOffsetChanged: context
          .read<ThreadNavigationButtonCubit>()
          .updateHistoryButtonPosition,
      builder: (BuildContext context, bool isDragging) {
        return <Widget>[
          _BackButton(isDragging: isDragging),
          SizedBoxes.pt12,
          _ForwardButton(isDragging: isDragging),
          if (isWebViewBottomSheetEnabled) const SizedBox(height: Dimens.pt64),
        ];
      },
    );
  }
}

/// A column of floating buttons that the user can drag around the screen.
class _DraggableButtonGroup extends StatefulWidget {
  const _DraggableButtonGroup({
    required this.offset,
    required this.onOffsetChanged,
    required this.builder,
  });

  /// The distance of the group from the right and bottom edges.
  final Offset offset;
  final void Function(double dx, double dy) onOffsetChanged;
  final List<Widget> Function(BuildContext context, bool isDragging) builder;

  @override
  State<_DraggableButtonGroup> createState() => _DraggableButtonGroupState();
}

class _DraggableButtonGroupState extends State<_DraggableButtonGroup> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double dx = widget.offset.dx;
    final double dy = widget.offset.dy;

    return Positioned(
      right: dx,
      bottom: dy,
      child: Material(
        color: Palette.transparent,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (DragUpdateDetails details) {
            widget.onOffsetChanged(
              (dx - details.delta.dx).clamp(0, size.width - 60),
              (dy - details.delta.dy).clamp(0, size.height - 60),
            );
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.builder(context, _isDragging),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDragging});

  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CommentsCubit, CommentsState, bool>(
      selector: (CommentsState state) => state.canNavigateBack,
      builder: (BuildContext context, bool canNavigateBack) {
        return _NavigationHistoryButton(
          icon: Icons.turn_left,
          tooltip: 'Back to previous position',
          isEnabled: canNavigateBack,
          isDragging: isDragging,
          onPressed: context.read<CommentsCubit>().navigateBack,
        );
      },
    );
  }
}

class _ForwardButton extends StatelessWidget {
  const _ForwardButton({required this.isDragging});

  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CommentsCubit, CommentsState, bool>(
      selector: (CommentsState state) => state.canNavigateForward,
      builder: (BuildContext context, bool canNavigateForward) {
        return _NavigationHistoryButton(
          icon: Icons.turn_right,
          tooltip: 'Forward to next position',
          isEnabled: canNavigateForward,
          isDragging: isDragging,
          onPressed: context.read<CommentsCubit>().navigateForward,
        );
      },
    );
  }
}

class _NavigationHistoryButton extends StatelessWidget {
  const _NavigationHistoryButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.isDragging,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final bool isDragging;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TapDownWrapper(
      child: AnimatedScale(
        scale: isDragging ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: isEnabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: FloatingActionButton(
            enableFeedback: false,
            tooltip: tooltip,
            backgroundColor: colorScheme.primaryContainer.withAlpha(200),

            /// Randomly generated string as heroTag to prevent default
            /// [FloatingActionButton] animation.
            heroTag: UniqueKey().hashCode,
            onPressed: isEnabled
                ? () {
                    HapticFeedbackUtils.selection();
                    onPressed();
                  }
                : null,
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
