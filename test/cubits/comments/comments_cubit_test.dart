import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  group('CommentsCubit.topMostVisibleItem', () {
    test('returns null when there are no positions', () {
      expect(CommentsCubit.topMostVisibleItem(const <ItemPosition>[]), isNull);
    });

    test('returns the item with the smallest index', () {
      const ItemPosition lower = ItemPosition(
        index: 12,
        itemLeadingEdge: 0.15,
        itemTrailingEdge: 0.4,
      );
      const ItemPosition top = ItemPosition(
        index: 8,
        itemLeadingEdge: -0.05,
        itemTrailingEdge: 0.14,
      );
      const ItemPosition below = ItemPosition(
        index: 13,
        itemLeadingEdge: 0.4,
        itemTrailingEdge: 0.9,
      );

      expect(
        CommentsCubit.topMostVisibleItem(<ItemPosition>[lower, top, below]),
        top,
      );
    });
  });
}
