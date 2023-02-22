import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/custom_linkify/linkifiers/linkifiers.dart';
import 'package:hacki/utils/utils.dart';

extension WidgetModifier on Widget {
  Widget padded([EdgeInsetsGeometry value = const EdgeInsets.all(12)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }

  Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState, {
    required BuildableComment comment,
  }) {
    final Iterable<EmphasisElement> emphasisElements =
        comment.elements.whereType<EmphasisElement>();
    final int start = editableTextState.textEditingValue.selection.base.offset;
    final int end = editableTextState.textEditingValue.selection.end;

    final List<ContextMenuButtonItem> items = <ContextMenuButtonItem>[
      ...editableTextState.contextMenuButtonItems,
    ];

    if (start != -1 && end != -1) {
      String selectedText = comment.text.substring(start, end);

      int count = 1;
      while (selectedText.contains(' ') && count <= emphasisElements.length) {
        final int s = (start + count * 2).clamp(0, comment.text.length);
        final int e = (end + count * 2).clamp(0, comment.text.length);
        selectedText = comment.text.substring(s, e);
        count++;
      }

      count = 1;
      while (selectedText.contains(' ') && count <= emphasisElements.length) {
        final int s = (start - count * 2).clamp(0, comment.text.length);
        final int e = (end - count * 2).clamp(0, comment.text.length);
        selectedText = comment.text.substring(s, e);
        count++;
      }

      items.addAll(<ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () => LinkUtil.launch(
            '''${Constants.wikipediaLink}$selectedText''',
          ),
          label: 'Wikipedia',
        ),
        ContextMenuButtonItem(
          onPressed: () => LinkUtil.launch(
            '''${Constants.wiktionaryLink}$selectedText''',
          ),
          label: 'Wiktionary',
        ),
      ]);
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }
}
