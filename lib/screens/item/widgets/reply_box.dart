import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/item.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/styles/styles.dart';
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

  static const double _collapsedHeight = 100;

  @override
  Widget build(BuildContext context) {
    expandedHeight ??= MediaQuery.of(context).size.height;
    return BlocConsumer<EditCubit, EditState>(
      listenWhen: (EditState previous, EditState current) =>
          previous.text != current.text,
      listener: (BuildContext context, EditState editState) {},
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
                      ? Dimens.zero
                      : widget.splitViewEnabled
                          ? MediaQuery.of(context).viewInsets.bottom
                          : Dimens.zero,
                ),
                child: AnimatedContainer(
                  height: expanded ? expandedHeight : _collapsedHeight,
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      if (!context.read<SplitViewCubit>().state.enabled)
                        BoxShadow(
                          color:
                              expanded ? Palette.transparent : Palette.black26,
                          blurRadius: Dimens.pt40,
                        ),
                    ],
                  ),
                  child: Material(
                    child: Column(
                      children: <Widget>[
                        if (context.read<SplitViewCubit>().state.enabled)
                          const Divider(
                            height: Dimens.zero,
                          ),
                        AnimatedContainer(
                          height: expanded ? Dimens.pt36 : Dimens.zero,
                          duration: const Duration(milliseconds: 200),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: Dimens.pt12,
                                  top: Dimens.pt8,
                                  bottom: Dimens.pt8,
                                ),
                                child: Text(
                                  replyingTo == null
                                      ? 'Editing'
                                      : 'Replying '
                                          '${replyingTo.by}',
                                  style: const TextStyle(color: Palette.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
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
                                        color: Palette.orange,
                                        size: TextDimens.pt18,
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
                                    color: Palette.orange,
                                    size: TextDimens.pt18,
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
                                  color: Palette.orange,
                                ),
                                onPressed: () {
                                  if (editState.text?.isNotEmpty ?? false) {
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        title: const Text('Save draft?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              context
                                                  .read<EditCubit>()
                                                  .deleteDraft();
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'No',
                                              style: TextStyle(
                                                color: Palette.red,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  widget.onCloseTapped();
                                  expanded = false;
                                },
                              ),
                            ],
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: Dimens.pt12,
                                  horizontal: Dimens.pt16,
                                ),
                                child: SizedBox(
                                  height: Dimens.pt24,
                                  width: Dimens.pt24,
                                  child: CircularProgressIndicator(
                                    color: Palette.orange,
                                    strokeWidth: Dimens.pt2,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                key: const Key('send'),
                                icon: const Icon(
                                  Icons.send,
                                  color: Palette.orange,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimens.pt16,
                            ),
                            child: TextField(
                              focusNode: widget.focusNode,
                              controller: widget.textEditingController,
                              maxLines: 100,
                              decoration: const InputDecoration(
                                alignLabelWithHint: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '...',
                                hintStyle: TextStyle(
                                  color: Palette.grey,
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
            horizontal: Dimens.pt12,
            vertical: Dimens.pt24,
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
                    left: Dimens.pt12,
                    top: Dimens.pt6,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        replyingTo?.by ?? '',
                        style: const TextStyle(color: Palette.grey),
                      ),
                      const Spacer(),
                      if (replyingTo != null)
                        TextButton(
                          child: const Text('View thread'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              expanded = false;
                            });
                            Navigator.popUntil(
                              context,
                              (Route<dynamic> route) =>
                                  route.settings.name == ItemScreen.routeName,
                            );
                            goToItemScreen(
                              args: ItemScreenArgs(
                                item: replyingTo,
                                useCommentCache: true,
                              ),
                              forceNewScreen: true,
                            );
                          },
                        ),
                      TextButton(
                        child: const Text('Copy all'),
                        onPressed: () => FlutterClipboard.copy(
                          replyingTo?.text ?? '',
                        ).then((_) => HapticFeedback.selectionClick()),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Palette.orange,
                          size: TextDimens.pt18,
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
                        left: Dimens.pt12,
                        right: Dimens.pt6,
                        top: Dimens.pt6,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableLinkify(
                          scrollPhysics: const NeverScrollableScrollPhysics(),
                          linkStyle: TextStyle(
                            fontSize: MediaQuery.of(context).textScaleFactor *
                                TextDimens.pt15,
                            color: Palette.orange,
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
