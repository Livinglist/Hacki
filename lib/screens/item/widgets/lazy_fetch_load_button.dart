import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/item/comment.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class LazyFetchLoadButton extends StatelessWidget {
  const LazyFetchLoadButton({required this.comment, super.key});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.pt12,
        ).copyWith(
          bottom: Dimens.pt6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: TextButton(
                onPressed: () {
                  HapticFeedbackUtils.selection();
                  context.read<CommentsCubit>().loadMore(comment: comment);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: Dimens.pt28,
                    ),
                    Text(
                      '''${comment.kids.length} ${comment.kids.length > 1 ? 'replies' : 'reply'}''',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
