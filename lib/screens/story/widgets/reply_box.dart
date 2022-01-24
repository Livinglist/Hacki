import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/item.dart';

class ReplyBox extends StatefulWidget {
  const ReplyBox({
    Key? key,
    required this.focusNode,
    required this.textEditingController,
    required this.replyingTo,
    required this.onSendTapped,
    required this.onCloseTapped,
    required this.onChanged,
    required this.isLoading,
  }) : super(key: key);

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final Item? replyingTo;
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
                        ? ''
                        : 'Replying '
                            '${widget.replyingTo?.by}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const Spacer(),
                if (widget.replyingTo != null && !widget.isLoading) ...[
                  IconButton(
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
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.orange,
                    ),
                    onPressed: widget.onCloseTapped,
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
                    icon: const Icon(
                      Icons.send,
                      color: Colors.orange,
                    ),
                    onPressed: widget.onSendTapped,
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
}
