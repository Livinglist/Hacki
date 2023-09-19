import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    required this.itemScrollController,
    required this.itemPositionsListener,
    super.key,
  });

  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (BuildContext context, CommentsState state) {
        return BlocBuilder<EditCubit, EditState>(
          buildWhen: (EditState previous, EditState current) =>
              previous.showReplyBox != current.showReplyBox,
          builder: (BuildContext context, EditState editState) {
            return AnimatedPadding(
              padding: editState.showReplyBox
                  ? const EdgeInsets.only(
                      bottom: Dimens.replyBoxCollapsedHeight,
                    )
                  : EdgeInsets.zero,
              duration: Durations.ms200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomDescribedFeatureOverlay(
                    feature: DiscoverableFeature.jumpUpButton,
                    contentLocation: ContentLocation.above,
                    tapTarget: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Palette.white,
                    ),
                    child: InkWell(
                      onLongPress: () => itemScrollController.scrollTo(
                        index: 0,
                        duration: Durations.ms400,
                      ),
                      child: FloatingActionButton.small(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,

                        /// Randomly generated string as heroTag to prevent
                        /// default [FloatingActionButton] animation.
                        heroTag: UniqueKey().hashCode,
                        onPressed: () {
                          HapticFeedbackUtil.selection();
                          context.read<CommentsCubit>().scrollToPreviousRoot(
                                itemScrollController,
                                itemPositionsListener,
                              );
                        },
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  CustomDescribedFeatureOverlay(
                    feature: DiscoverableFeature.jumpDownButton,
                    tapTarget: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Palette.white,
                    ),
                    child: InkWell(
                      onLongPress: () => itemScrollController.scrollTo(
                        index: state.comments.length,
                        duration: Durations.ms400,
                      ),
                      child: FloatingActionButton.small(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,

                        /// Same as above.
                        heroTag: UniqueKey().hashCode,
                        onPressed: () {
                          HapticFeedbackUtil.selection();
                          context.read<CommentsCubit>().scrollToNextRoot(
                                itemScrollController,
                                itemPositionsListener,
                              );
                        },
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
