import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/item.dart';
import 'package:hacki/utils/link_util.dart';

class ReplyBox extends StatefulWidget {
  const ReplyBox({
    super.key,
    this.splitViewEnabled = false,
    required this.focusNode,
    required this.textEditingController,
    required this.onSendTapped,
    required this.onCloseTapped,
    required this.onChanged,
  });

  final bool splitViewEnabled;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final VoidCallback onSendTapped;
  final VoidCallback onCloseTapped;
  final ValueChanged<String> onChanged;

  @override
  _ReplyBoxState createState() => _ReplyBoxState();
}

class _ReplyBoxState extends State<ReplyBox> {
  bool expanded = false;
  double? expandedHeight;

  @override
  Widget build(BuildContext context) {
    expandedHeight ??= MediaQuery.of(context).size.height;
    return BlocBuilder<EditCubit, EditState>(
      buildWhen: (EditState previous, EditState current) =>
          previous.showReplyBox != current.showReplyBox ||
          previous.itemBeingEdited != current.itemBeingEdited ||
          previous.replyingTo != current.replyingTo,
      builder: (BuildContext context, EditState editState) {
        return Visibility(
          visible: editState.showReplyBox,
          child: BlocBuilder<PostCubit, PostState>(
            builder: (BuildContext context, PostState postState) {
              final Item? replyingTo = editState.replyingTo;
              final bool isLoading = postState.status == PostStatus.loading;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: expanded
                      ? 0
                      : widget.splitViewEnabled
                          ? MediaQuery.of(context).viewInsets.bottom
                          : 0,
                ),
                child: AnimatedContainer(
                  height: expanded ? expandedHeight : 100,
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      if (!context.read<SplitViewCubit>().state.enabled)
                        BoxShadow(
                          color: expanded ? Colors.transparent : Colors.black26,
                          blurRadius: 40,
                        ),
                    ],
                  ),
                  child: Material(
                    child: Column(
                      children: <Widget>[
                        if (context.read<SplitViewCubit>().state.enabled)
                          const Divider(
                            height: 0,
                          ),
                        AnimatedContainer(
                          height: expanded ? 36 : 0,
                          duration: const Duration(milliseconds: 200),
                        ),
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                replyingTo == null
                                    ? 'Editing'
                                    : 'Replying '
                                        '${replyingTo.by}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            const Spacer(),
                            if (!isLoading) ...<Widget>[
                              ...<Widget>[
                                if (replyingTo != null)
                                  AnimatedOpacity(
                                    opacity: expanded ? 1 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: IconButton(
                                      key: const Key('quote'),
                                      icon: const Icon(
                                        FeatherIcons.code,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      onPressed:
                                          expanded ? showTextPopup : null,
                                    ),
                                  ),
                                IconButton(
                                  key: const Key('expand'),
                                  icon: Icon(
                                    expanded
                                        ? FeatherIcons.minimize2
                                        : FeatherIcons.maximize2,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      expanded = !expanded;
                                    });
                                  },
                                ),
                              ],
                              IconButton(
                                key: const Key('close'),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  widget.onCloseTapped();
                                  expanded = false;
                                },
                              ),
                            ],
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                key: const Key('send'),
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  widget.onSendTapped();
                                  expanded = false;
                                },
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              focusNode: widget.focusNode,
                              controller: widget.textEditingController,
                              maxLines: 100,
                              decoration: const InputDecoration(
                                alignLabelWithHint: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                focusedBorder: InputBorder.none,
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              onChanged: widget.onChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showTextPopup() {
    final Item? replyingTo = context.read<EditCubit>().state.replyingTo;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 500,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 6,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        replyingTo?.by ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton(
                        child: const Text('Copy All'),
                        onPressed: () => FlutterClipboard.copy(
                          replyingTo?.text ?? '',
                        ).then((_) => HapticFeedback.selectionClick()),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.orange,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 6,
                        top: 6,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableLinkify(
                          scrollPhysics: const NeverScrollableScrollPhysics(),
                          linkStyle: TextStyle(
                            fontSize:
                                MediaQuery.of(context).textScaleFactor * 15,
                            color: Colors.orange,
                          ),
                          onOpen: (LinkableElement link) =>
                              LinkUtil.launch(link.url),
                          text: replyingTo?.text ?? '',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
