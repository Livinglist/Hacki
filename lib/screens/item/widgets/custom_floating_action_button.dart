import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/custom_described_feature_overlay.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    super.key,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.alignment,
  });

  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final double alignment;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (BuildContext context, CommentsState state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomDescribedFeatureOverlay(
              featureId: Constants.featureJumpUpButton,
              tapTarget: Icon(
                Icons.keyboard_arrow_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Jump to previous root level comment.'),
              description: const Text(
                '''Tapping on this button will take you to the previous off-screen root level comment.''',
              ),
              child: FloatingActionButton.small(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                heroTag: 'heroTag1',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<CommentsCubit>().jumpUp(
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
            CustomDescribedFeatureOverlay(
              featureId: Constants.featureJumpDownButton,
              tapTarget: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Jump to next root level comment.'),
              description: const Text(
                '''Tapping on this button will take you to the next off-screen root level comment.''',
              ),
              child: FloatingActionButton.small(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                heroTag: 'heroTag2',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<CommentsCubit>().jump(
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
          ],
        );
      },
    );
  }
}
