import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
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
      child: BlocBuilder<CommentsCubit, CommentsState>(
        builder: (context, state) {
          return BlocBuilder<BlocklistCubit, BlocklistState>(
            builder: (context, blocklistState) {
              const r = 255;
              var g = widget.level * 40 < 255
                  ? 152
                  : (widget.level * 20).clamp(0, 255);
              var b = (widget.level * 40).clamp(0, 255);

              if (g == 255 && b == 255) {
                g = (widget.level * 30 - 255).clamp(0, 255);
                b = (widget.level * 40 - 255).clamp(0, 255);
              }

              return InkWell(
                onTap: () => widget.onTap(widget.comment),
                onLongPress: () => widget.onLongPress(widget.comment),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 6, right: 6, top: 6),
                        child: Row(
                          children: [
                            Text(
                              widget.comment.by,
                              style: TextStyle(
                                //255, 152, 0
                                color: Color.fromRGBO(
                                  r,
                                  g,
                                  b,
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
                      else if (blocklistState.blocklist
                          .contains(widget.comment.by))
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
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 6,
                            bottom: 12,
                          ),
                          child: Linkify(
                            key: ObjectKey(widget.comment),
                            text: widget.comment.text,
                            onOpen: (link) => LinkUtil.launchUrl(link.url),
                          ),
                        ),
                      const Divider(
                        height: 0,
                      ),
                      if (widget.loadKids)
                        Padding(
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
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
