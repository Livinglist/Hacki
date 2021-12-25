import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    Key? key,
    required this.comment,
  }) : super(key: key);

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentsCubit(commentIds: comment.kids),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6, top: 6),
              child: Row(
                children: [
                  Text(
                    comment.by,
                    style: const TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    comment.postedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (comment.deleted)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'deleted',
                    style: TextStyle(color: Colors.white30),
                  ),
                ),
              ),
            Html(
              data: comment.text,
              onLinkTap: (link, _, __, ___) {
                final url = Uri.encodeFull(link ?? '');
                canLaunch(url).then((val) {
                  if (val) {
                    launch(url);
                  }
                });
              },
            ),
            const Divider(
              height: 0,
            ),
            BlocBuilder<CommentsCubit, CommentsState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: state.comments
                        .map((e) => CommentTile(comment: e))
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
