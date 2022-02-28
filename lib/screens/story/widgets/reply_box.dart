import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/models/item.dart';
import 'package:hacki/utils/link_util.dart';

class ReplyBox extends StatefulWidget {
  const ReplyBox({
    Key? key,
    required this.focusNode,
    required this.textEditingController,
    required this.replyingTo,
    required this.editing,
    required this.onSendTapped,
    required this.onCloseTapped,
    required this.onChanged,
    required this.isLoading,
  }) : super(key: key);

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final Item? replyingTo;
  final Item? editing;
  final VoidCallback onSendTapped;
  final VoidCallback onCloseTapped;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  _ReplyBoxState createState() => _ReplyBoxState();
}

class _ReplyBoxState extends State<ReplyBox> {
  bool expanded = false;
  double? expandedHeight;
  double? topPadding;

  @override
  Widget build(BuildContext context) {
    expandedHeight ??= MediaQuery.of(context).size.height;
    topPadding ??= MediaQuery.of(context).padding.top + kToolbarHeight;
    return AnimatedContainer(
      height: expanded ? expandedHeight : 100,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: expanded ? Colors.transparent : Colors.black54,
            offset: const Offset(0, 20), //(x,y)
            blurRadius: 40,
          ),
        ],
      ),
      child: Material(
        child: Column(
          children: [
            AnimatedContainer(
              height: expanded ? topPadding : 0,
              duration: const Duration(milliseconds: 200),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    widget.replyingTo == null
                        ? 'Editing'
                        : 'Replying '
                            '${widget.replyingTo?.by}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const Spacer(),
                if (!widget.isLoading) ...[
                  if (widget.replyingTo != null) ...[
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
                        onPressed: expanded ? showTextPopup : null,
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
                if (widget.isLoading)
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
                  textInputAction: TextInputAction.newline,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showTextPopup() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 64,
            bottom: 64,
          ),
          color: Theme.of(context).canvasColor,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 6,
              top: 6,
              bottom: 12,
            ),
            child: Column(
              children: [
                Material(
                  child: Row(
                    children: [
                      Text(
                        widget.replyingTo?.by ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton(
                        child: const Text('Copy All'),
                        onPressed: () => FlutterClipboard.copy(
                          widget.replyingTo?.text ?? '',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.orange,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(
                        width: 6,
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    isAlwaysShown: true,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SingleChildScrollView(
                        child: SelectableLinkify(
                          scrollPhysics: const NeverScrollableScrollPhysics(),
                          text: widget.replyingTo?.text ?? '',
                          onOpen: (link) => LinkUtil.launchUrl(link.url),
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
