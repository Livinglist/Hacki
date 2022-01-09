import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/utils.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    Key? key,
    required this.comment,
    required this.onTap,
    required this.onLongPress,
    this.loadKids = true,
    this.level = 0,
  }) : super(key: key);

  final Comment comment;
  final int level;
  final bool loadKids;
  final Function(Comment) onTap;
  final Function(Comment) onLongPress;

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>(
      create: (_) => CommentsCubit(commentIds: widget.comment.kids),
      child: BlocBuilder<BlocklistCubit, BlocklistState>(
        builder: (context, blocklistState) {
          return InkWell(
            onTap: () => widget.onTap(widget.comment),
            onLongPress: () => widget.onLongPress(widget.comment),
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
                          widget.comment.by,
                          style: TextStyle(
                            //255, 152, 0
                            color: Color.fromRGBO(
                              255,
                              widget.level * 40 < 255
                                  ? 152
                                  : (widget.level * 20).clamp(0, 255),
                              (widget.level * 40).clamp(0, 255),
                              1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.comment.postedDate,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.comment.deleted)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'deleted',
                          style: TextStyle(color: Colors.white30),
                        ),
                      ),
                    )
                  else if (blocklistState.blocklist.contains(widget.comment.by))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'blocked',
                          style: TextStyle(color: Colors.white30),
                        ),
                      ),
                    )
                  else
                    Html(
                      data: widget.comment.text,
                      onLinkTap: (link, _, __, ___) =>
                          LinkUtil.launchUrl(link ?? ''),
                    ),
                  const Divider(
                    height: 0,
                  ),
                  if (widget.loadKids)
                    BlocBuilder<CommentsCubit, CommentsState>(
                      builder: (context, state) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: state.comments
                                .map((e) => FadeIn(
                                      child: CommentTile(
                                        comment: e,
                                        onTap: widget.onTap,
                                        onLongPress: widget.onLongPress,
                                        level: widget.level + 1,
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
