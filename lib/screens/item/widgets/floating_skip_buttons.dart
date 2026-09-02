import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class FloatingSkipButtons extends StatefulWidget {
  const FloatingSkipButtons({super.key});

  @override
  State<FloatingSkipButtons> createState() => _FloatingSkipButtonsState();
}

class _FloatingSkipButtonsState extends State<FloatingSkipButtons> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWebViewBottomSheetEnabled = context
        .select<PreferenceCubit, bool>(
          (PreferenceCubit cubit) => cubit.state.isWebViewBottomSheetEnabled,
        );
    final ThreadNavigationButtonState threadNavButtonsPos = context
        .watch<ThreadNavigationButtonCubit>()
        .state;
    final double dx = threadNavButtonsPos.dx;
    final double dy = threadNavButtonsPos.dy;

    return Positioned(
      right: dx,
      bottom: dy,
      child: Material(
        color: Palette.transparent,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (DragUpdateDetails details) {
            final Offset updatedOffset = Offset(
              (dx - details.delta.dx).clamp(0, size.width - 60),
              (dy - details.delta.dy).clamp(0, size.height - 60),
            );
            context.read<ThreadNavigationButtonCubit>().updateButtonPosition(
              updatedOffset.dx,
              updatedOffset.dy,
            );
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          child: BlocBuilder<EditCubit, EditState>(
            buildWhen: (EditState previous, EditState current) =>
                previous.showReplyBox != current.showReplyBox,
            builder: (BuildContext context, EditState editState) {
              return AnimatedPadding(
                padding: editState.showReplyBox
                    ? const EdgeInsets.only(
                        bottom: Dimens.replyBoxCollapsedHeight,
                      )
                    : EdgeInsets.zero,
                duration: AppDurations.ms200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CustomDescribedFeatureOverlay(
                      feature: DiscoverableFeature.jumpUpButton,
                      contentLocation: ContentLocation.above,
                      tapTarget: Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: TapDownWrapper(
                        child: AnimatedScale(
                          scale: _isDragging ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: InkWell(
                            enableFeedback: false,
                            onLongPress: () {
                              HapticFeedbackUtils.light();
                              context.read<CommentsCubit>().scrollTo(index: 0);
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
                                context
                                    .read<CommentsCubit>()
                                    .scrollToPreviousRoot();
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
                          scale: _isDragging ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: InkWell(
                            enableFeedback: false,
                            onLongPress: () {
                              HapticFeedbackUtils.light();
                              final CommentsCubit cubit = context
                                  .read<CommentsCubit>();
                              cubit.scrollTo(
                                index: cubit.state.comments.length - 1,
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
                                    content:
                                        '''No more root level comment below.''',
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isWebViewBottomSheetEnabled)
                      const SizedBox(height: Dimens.pt64),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
