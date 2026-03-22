import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class UpvoteSlidableAction extends StatefulWidget {
  const UpvoteSlidableAction({
    required this.item,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final Item item;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<UpvoteSlidableAction> createState() => _UpvoteSlidableActionState();
}

class _UpvoteSlidableActionState extends State<UpvoteSlidableAction>
    with ItemActionMixin {
  @override
  Widget build(BuildContext context) {
    final Item item = widget.item;
    return BlocBuilder<VoteCubit, VoteState>(
      builder: (BuildContext context, VoteState voteState) {
        return CustomSlidableAction(
          onPressed: (BuildContext context) {
            HapticFeedbackUtil.light();
            context.read<VoteCubit>().upvote();
          },
          backgroundColor: widget.backgroundColor ??
              Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: widget.foregroundColor ??
              Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(
            FeatherIcons.chevronUp,
            color: voteState.vote == Vote.up
                ? Theme.of(context).colorScheme.primary
                : null,
            size: Dimens.pt24,
          ),
        );
      },
    );
  }
}
