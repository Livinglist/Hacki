import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/services/dialog_proxy.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

extension ContextMenuBuilder on Widget {
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
      late final String text;
      if (item is Buildable) {
        text = (item as Buildable)
            .elements
            .map((LinkifyElement e) => e.text)
            .reduce((String value, String e) => '$value$e');
      } else {
        text = item.text;
      }

      final String selectedText = text.substring(start, end);
      items
        ..insert(
          0,
          ContextMenuButtonItem(
            onPressed: () => DialogProxy.showHackerNewsSearchBottomSheet(
              context,
              selectedText,
            ),
            label: 'Search HN',
          ),
        )
        ..addAll(<ContextMenuButtonItem>[
          ContextMenuButtonItem(
            onPressed: () => LinkUtils.launch(
              '''${Constants.wikipediaLink}$selectedText''',
              context,
            ),
            label: 'Wikipedia',
          ),
          ContextMenuButtonItem(
            onPressed: () => LinkUtils.launch(
              '''${Constants.wiktionaryLink}$selectedText''',
              context,
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
