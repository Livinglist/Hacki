import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

extension ContextMenuBuilder on Widget {
  Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState, {
    required Item item,
  }) {
    if (item is! Buildable) {
      return const SizedBox.shrink();
    }

    final int start = editableTextState.textEditingValue.selection.base.offset;
    final int end = editableTextState.textEditingValue.selection.end;

    final List<ContextMenuButtonItem> items = <ContextMenuButtonItem>[
      ...editableTextState.contextMenuButtonItems,
    ];

    if (start != -1 && end != -1) {
      final String text = (item as Buildable)
          .elements
          .map((LinkifyElement e) => e.text)
          .reduce((String value, String e) => '$value$e');
      final String selectedText = text.substring(start, end);

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

extension WidgetModifier on Widget {
  Widget padded([
    EdgeInsetsGeometry value = const EdgeInsets.all(Dimens.pt12),
  ]) {
    return Padding(
      padding: value,
      child: this,
    );
  }
}
