import 'dart:convert';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:material_ui/material_ui.dart' show IconData, Icons;

/// Names are persisted, so keep them stable when changing labels or icons.
enum ItemMenuAction {
  viewProfile('View Profile', icon: Icons.account_circle),
  searchOnHackerNews('Search on HN', icon: Icons.search),
  searchInThread('Search in thread', icon: Icons.manage_search),
  reply('Reply', icon: Icons.message),
  upvote('Upvote', icon: Icons.thumb_up_off_alt_outlined),
  downvote('Downvote', icon: Icons.thumb_down_off_alt_outlined),
  favorite('Favorite', icon: Icons.favorite_border),
  share('Share', icon: FeatherIcons.share),
  flag('Flag', icon: Icons.local_police),
  block('Block', icon: Icons.visibility_off),
  viewInSeparateThread('View In Separate Thread', icon: Icons.list),
  viewInBrowser('View in Browser', icon: Icons.open_in_browser);

  const ItemMenuAction(this.description, {required this.icon});

  final String description;
  final IconData icon;
}

/// Keeps hidden actions in the order so enabling one restores its position.
class ItemMenuConfiguration {
  ItemMenuConfiguration({
    Iterable<ItemMenuAction> order = ItemMenuAction.values,
    Iterable<ItemMenuAction> disabled = const <ItemMenuAction>[],
  }) : order = List<ItemMenuAction>.unmodifiable(<ItemMenuAction>{
         ...order,
         ...ItemMenuAction.values,
       }),
       disabled = Set<ItemMenuAction>.unmodifiable(disabled);

  factory ItemMenuConfiguration.fromString(String value) {
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return ItemMenuConfiguration();
      }

      Iterable<ItemMenuAction> readActions(Object? names) {
        if (names is! List<dynamic>) return const <ItemMenuAction>[];

        return names.expand((dynamic name) {
          return ItemMenuAction.values.where(
            (ItemMenuAction action) => action.name == name,
          );
        });
      }

      return ItemMenuConfiguration(
        order: readActions(decoded['order']),
        disabled: readActions(decoded['disabled']),
      );
    } on FormatException {
      return ItemMenuConfiguration();
    }
  }

  final List<ItemMenuAction> order;
  final Set<ItemMenuAction> disabled;

  List<ItemMenuAction> get enabledActions => order
      .where((ItemMenuAction action) => !disabled.contains(action))
      .toList(growable: false);

  ItemMenuConfiguration withOrder(Iterable<ItemMenuAction> order) =>
      ItemMenuConfiguration(order: order, disabled: disabled);

  ItemMenuConfiguration withEnabled(
    ItemMenuAction action, {
    required bool enabled,
  }) {
    final Set<ItemMenuAction> updated = <ItemMenuAction>{...disabled};
    if (enabled) {
      updated.remove(action);
    } else {
      updated.add(action);
    }
    return ItemMenuConfiguration(order: order, disabled: updated);
  }

  String encode() => jsonEncode(<String, List<String>>{
    'order': order.map((ItemMenuAction action) => action.name).toList(),
    'disabled': disabled.map((ItemMenuAction action) => action.name).toList(),
  });
}
