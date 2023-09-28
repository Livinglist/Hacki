import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/screens/widgets/item_text.dart';
import 'package:hacki/utils/utils.dart';

extension WidgetModifier on ItemText {
  Widget padded([EdgeInsetsGeometry value = const EdgeInsets.all(12)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }

  Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState, {
    required Item item,
  }) {
    final int start = editableTextState.textEditingValue.selection.base.offset;
    final int end = editableTextState.textEditingValue.selection.end;

    final List<ContextMenuButtonItem> items = <ContextMenuButtonItem>[
      ...editableTextState.contextMenuButtonItems,
    ];

    if (start != -1 && end != -1) {
      String selectedText = item.text.substring(start, end);

      if (item is Buildable) {
        final Iterable<EmphasisElement> emphasisElements =
            (item as Buildable).elements.whereType<EmphasisElement>();

        int count = 1;
        while (selectedText.contains(' ') && count <= emphasisElements.length) {
          final int s = (start + count * 2).clamp(0, item.text.length);
          final int e = (end + count * 2).clamp(0, item.text.length);
          selectedText = item.text.substring(s, e);
          count++;
        }

        count = 1;
        while (selectedText.contains(' ') && count <= emphasisElements.length) {
          final int s = (start - count * 2).clamp(0, item.text.length);
          final int e = (end - count * 2).clamp(0, item.text.length);
          selectedText = item.text.substring(s, e);
          count++;
        }
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
