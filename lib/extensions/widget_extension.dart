import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/search/search_screen.dart';
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
      items
        ..insert(
          0,
          ContextMenuButtonItem(
            onPressed: () => _showHackerNewsSearchBottomSheet(
              context,
              selectedText,
            ),
            label: 'Search HN',
          ),
        )
        ..addAll(<ContextMenuButtonItem>[
          ContextMenuButtonItem(
            onPressed: () => LinkUtil.launch(
              '''${Constants.wikipediaLink}$selectedText''',
              context,
            ),
            label: 'Wikipedia',
          ),
          ContextMenuButtonItem(
            onPressed: () => LinkUtil.launch(
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

  void _showHackerNewsSearchBottomSheet(
    BuildContext context,
    String text,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return BlocProvider<SearchCubit>(
          create: (_) => SearchCubit()..search(text),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - Dimens.pt120,
            child: const Column(
              children: <Widget>[
                Expanded(
                  child: SearchScreen(
                    isInBottomSheet: true,
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
