import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/custom_described_feature_overlay.dart';
import 'package:hacki/styles/palette.dart';
import 'package:hacki/utils/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    super.key,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (BuildContext context, CommentsState state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomDescribedFeatureOverlay(
              featureId: Constants.featureJumpUpButton,
              contentLocation: ContentLocation.above,
              tapTarget: Icon(
                Icons.keyboard_arrow_up,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              title: const Text('Jump to previous root level comment.'),
              description: const Text(
                '''Tapping on this button will take you to the previous off-screen root level comment.''',
              ),
              child: FloatingActionButton.small(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                /// Randomly generated string as heroTag to prevent
                /// default [FloatingActionButton] animation.
                heroTag: UniqueKey().hashCode,
                onPressed: () {
                  if (state.status == CommentsStatus.loading) return;

                  HapticFeedbackUtil.selection();
                  context.read<CommentsCubit>().jumpUp(
                        itemScrollController,
                        itemPositionsListener,
                      );
                },
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Palette.white,
                ),
              ),
            ),
            CustomDescribedFeatureOverlay(
              featureId: Constants.featureJumpDownButton,
              tapTarget: const Icon(
                Icons.keyboard_arrow_down,
                color: Palette.white,
              ),
              title: const Text('Jump to next root level comment.'),
              description: const Text(
                '''Tapping on this button will take you to the next off-screen root level comment.''',
              ),
              child: FloatingActionButton.small(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                /// Same as above.
                heroTag: UniqueKey().hashCode,
                onPressed: () {
                  if (state.status == CommentsStatus.loading) return;

                  HapticFeedbackUtil.selection();
                  context.read<CommentsCubit>().jump(
                        itemScrollController,
                        itemPositionsListener,
                      );
                },
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: state.status == CommentsStatus.loading
                      ? Palette.grey
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
