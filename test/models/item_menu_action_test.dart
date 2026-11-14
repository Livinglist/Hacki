import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/models/item_menu_action.dart';

void main() {
  group('ItemMenuConfiguration', () {
    test('starts with all actions enabled in the existing order', () {
      final ItemMenuConfiguration configuration = ItemMenuConfiguration();

      expect(configuration.order, ItemMenuAction.values);
      expect(configuration.enabledActions, ItemMenuAction.values);
    });

    test('round trips stable action names, order, and visibility', () {
      final ItemMenuConfiguration original = ItemMenuConfiguration(
        order: ItemMenuAction.values.reversed,
        disabled: <ItemMenuAction>[ItemMenuAction.share, ItemMenuAction.block],
      );
      final ItemMenuConfiguration restored = ItemMenuConfiguration.fromString(
        original.encode(),
      );

      expect(restored.order, original.order);
      expect(restored.disabled, original.disabled);
      expect(restored.enabledActions, isNot(contains(ItemMenuAction.share)));
      expect(original.encode(), contains('viewProfile'));
    });

    test('ignores unknown and duplicate names and appends missing actions', () {
      final ItemMenuConfiguration configuration =
          ItemMenuConfiguration.fromString(
            '{"order":["share","missing","share",7,"reply"],'
            '"disabled":["block","missing","block",null]}',
          );

      expect(configuration.order.take(2), <ItemMenuAction>[
        ItemMenuAction.share,
        ItemMenuAction.reply,
      ]);
      expect(configuration.order.length, ItemMenuAction.values.length);
      expect(configuration.order.toSet(), ItemMenuAction.values.toSet());
      expect(configuration.disabled, <ItemMenuAction>{ItemMenuAction.block});
      expect(
        configuration.enabledActions,
        contains(ItemMenuAction.viewProfile),
      );
    });

    test('falls back to defaults for malformed saved data', () {
      for (final String data in <String>[
        '',
        'not JSON',
        'null',
        '[]',
        '{"order":true,"disabled":{}}',
      ]) {
        final ItemMenuConfiguration configuration =
            ItemMenuConfiguration.fromString(data);
        expect(configuration.order, ItemMenuAction.values, reason: data);
        expect(
          configuration.enabledActions,
          ItemMenuAction.values,
          reason: data,
        );
      }
    });

    test('disabling and re-enabling preserves the position', () {
      final ItemMenuConfiguration reordered = ItemMenuConfiguration(
        order: ItemMenuAction.values.reversed,
      );
      final ItemMenuConfiguration hidden = reordered.withEnabled(
        ItemMenuAction.share,
        enabled: false,
      );
      final ItemMenuConfiguration enabled = hidden.withEnabled(
        ItemMenuAction.share,
        enabled: true,
      );

      expect(hidden.order, reordered.order);
      expect(hidden.enabledActions, isNot(contains(ItemMenuAction.share)));
      expect(enabled.enabledActions, reordered.order);
    });

    test('supports hiding every action', () {
      final ItemMenuConfiguration configuration = ItemMenuConfiguration(
        disabled: ItemMenuAction.values,
      );

      expect(configuration.enabledActions, isEmpty);
      expect(configuration.order, ItemMenuAction.values);
    });
  });
}
