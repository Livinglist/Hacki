import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                  onLongPress: () =>
                      context.read<CommentsCubit>().scrollTo(index: 0),
                  child: FloatingActionButton.small(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                    /// Randomly generated string as heroTag to prevent
                    /// default [FloatingActionButton] animation.
                    heroTag: UniqueKey().hashCode,
                    onPressed: () {
                      HapticFeedbackUtil.selection();
                      context.read<CommentsCubit>().scrollToPreviousRoot();
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
                  onLongPress: () {
                    final CommentsCubit cubit = context.read<CommentsCubit>();
                    cubit.scrollTo(index: cubit.state.comments.length);
                  },
                  child: FloatingActionButton.small(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,

                    /// Same as above.
                    heroTag: UniqueKey().hashCode,
                    onPressed: () {
                      HapticFeedbackUtil.selection();
                      context.read<CommentsCubit>().scrollToNextRoot(
                            onError: () => context.showSnackBar(
                              content: '''No more root level comment below.''',
                            ),
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
  }
}
