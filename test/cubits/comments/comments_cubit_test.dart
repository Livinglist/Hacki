import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
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

  group('CommentsCubit.currentAnchorItem', () {
    test('returns null when nothing is visible', () {
      expect(
        CommentsCubit.currentAnchorItem(const <ItemPosition>[], lastIndex: 5),
        isNull,
      );
    });

    test('prefers the item a jump landed on over the one above it', () {
      const ItemPosition above = ItemPosition(
        index: 3,
        itemLeadingEdge: -0.2,
        itemTrailingEdge: 0.15,
      );
      const ItemPosition landed = ItemPosition(
        index: 4,
        itemLeadingEdge: 0.15,
        itemTrailingEdge: 0.6,
      );

      expect(
        CommentsCubit.currentAnchorItem(<ItemPosition>[
          landed,
          above,
        ], lastIndex: 5),
        landed,
      );
    });

    test('falls back to the topmost visible item', () {
      const ItemPosition offScreen = ItemPosition(
        index: 1,
        itemLeadingEdge: -0.9,
        itemTrailingEdge: -0.3,
      );
      const ItemPosition top = ItemPosition(
        index: 2,
        itemLeadingEdge: -0.3,
        itemTrailingEdge: 0.5,
      );
      const ItemPosition below = ItemPosition(
        index: 3,
        itemLeadingEdge: 0.5,
        itemTrailingEdge: 0.9,
      );

      expect(
        CommentsCubit.currentAnchorItem(<ItemPosition>[
          below,
          top,
          offScreen,
        ], lastIndex: 5),
        top,
      );
    });

    test('ignores the footer after the last comment', () {
      const ItemPosition footer = ItemPosition(
        index: 6,
        itemLeadingEdge: 0.1,
        itemTrailingEdge: 1.1,
      );

      expect(
        CommentsCubit.currentAnchorItem(<ItemPosition>[footer], lastIndex: 5),
        isNull,
      );
    });
  });

  group('CommentsState navigation stack', () {
    const NavigationAnchor a = NavigationAnchor(itemId: 1, alignment: 0);
    const NavigationAnchor b = NavigationAnchor(itemId: 2, alignment: 0.15);
    const NavigationAnchor c = NavigationAnchor(itemId: 3, alignment: 0.15);
    const NavigationAnchor d = NavigationAnchor(itemId: 4, alignment: 0.15);

    late CommentsState state;

    setUp(() {
      state = CommentsState.init(
        isOfflineReading: false,
        item: Story.placeholder(),
        fetchMode: FetchMode.eager,
        order: CommentsOrder.natural,
      );
    });

    test('starts empty with nowhere to navigate', () {
      expect(state.navigationStack, isEmpty);
      expect(state.canNavigateBack, isFalse);
      expect(state.canNavigateForward, isFalse);
    });

    test('a jump records where the user was and where they went', () {
      state = state.copyWithNavigation(from: a, to: b);

      expect(state.navigationStack, <NavigationAnchor>[a, b]);
      expect(state.navigationIndex, 1);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test('consecutive jumps do not duplicate the position in between', () {
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, b, c]);
      expect(state.navigationIndex, 2);
    });

    test('remembers how far the user scrolled before jumping again', () {
      const NavigationAnchor scrolledB = NavigationAnchor(
        itemId: 2,
        alignment: -0.4,
      );

      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: scrolledB, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, scrolledB, c]);
    });

    test(
      'updates the current stop when another comment anchors the viewport',
      () {
        const NavigationAnchor aboveB = NavigationAnchor(
          itemId: 22,
          alignment: 0.08,
        );

        state = state
            .copyWithNavigation(from: a, to: b)
            .copyWithNavigation(from: aboveB, to: c);

        expect(state.navigationStack, <NavigationAnchor>[a, aboveB, c]);
        expect(state.navigationIndex, 2);
      },
    );

    test('keeps the selected comment when the measured viewport changes', () {
      final Comment target = Comment.fromJson(const <String, dynamic>{
        'id': 2,
        'text': 'Selected comment',
      });
      final NavigationAnchor destination = NavigationAnchor.forComment(
        target,
        alignment: 0.15,
      );
      const NavigationAnchor aboveTarget = NavigationAnchor(
        itemId: 22,
        alignment: 0.08,
      );

      state = state
          .copyWithNavigation(from: a, to: destination)
          .copyWithNavigation(from: aboveTarget, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, destination, c]);
      expect(state.navigationStack[1].targetComment, same(target));
    });

    test('a target comment survives a new jump after Back', () {
      final Comment target = Comment.fromJson(const <String, dynamic>{'id': 2});
      final NavigationAnchor destination = NavigationAnchor.forComment(
        target,
        alignment: 0.15,
      );

      state = state
          .copyWithNavigation(from: a, to: destination)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 1)
          .copyWithNavigation(
            from: const NavigationAnchor(itemId: 22, alignment: 0.08),
            to: d,
          );

      expect(state.navigationStack, <NavigationAnchor>[a, destination, d]);
      expect(state.navigationStack[1].targetComment, same(target));
      expect(state.canNavigateForward, isFalse);
    });

    test(
      'selecting the current position attaches its target without a stop',
      () {
        final Comment target = Comment.fromJson(const <String, dynamic>{
          'id': 2,
        });
        final NavigationAnchor destination = NavigationAnchor.forComment(
          target,
          alignment: 0.15,
        );
        state = state
            .copyWithNavigation(from: a, to: b)
            .copyWithNavigation(from: b, to: c)
            .copyWith(navigationIndex: 1)
            .copyWithNavigation(from: destination, to: destination);

        expect(state.navigationStack, <NavigationAnchor>[a, destination]);
        expect(state.navigationStack.last.targetComment, same(target));
        expect(state.canNavigateForward, isFalse);
      },
    );

    test('selecting an already visible comment retains the first target', () {
      final Comment target = Comment.fromJson(const <String, dynamic>{'id': 2});
      final NavigationAnchor destination = NavigationAnchor.forComment(
        target,
        alignment: 0.15,
      );

      state = state.copyWithNavigation(from: destination, to: destination);

      expect(state.navigationStack, <NavigationAnchor>[destination]);
      expect(state.navigationStack.single.targetComment, same(target));
      expect(state.canNavigateBack, isFalse);
    });

    test('preserves earlier stops when returning to a preceding origin', () {
      const NavigationAnchor scrolledA = NavigationAnchor(
        itemId: 1,
        alignment: -0.1,
      );

      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: scrolledA, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, b, scrolledA, c]);
      expect(state.navigationIndex, 3);
    });

    test(
      'refreshes the current origin and clears forward positions after Back',
      () {
        const NavigationAnchor scrolledB = NavigationAnchor(
          itemId: 22,
          alignment: -0.4,
        );

        state = state
            .copyWithNavigation(from: a, to: b)
            .copyWithNavigation(from: b, to: c)
            .copyWith(navigationIndex: 1)
            .copyWithNavigation(from: scrolledB, to: d);

        expect(state.navigationStack, <NavigationAnchor>[a, scrolledB, d]);
        expect(state.navigationIndex, 2);
        expect(state.canNavigateBack, isTrue);
        expect(state.canNavigateForward, isFalse);
      },
    );

    test('a jump from the first stop clears every forward position', () {
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 0);
      expect(state.canNavigateForward, isTrue);

      state = state.copyWithNavigation(from: a, to: d);

      expect(state.navigationStack, <NavigationAnchor>[a, d]);
      expect(state.navigationIndex, 1);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test('a jump to the next forward position clears all later stops', () {
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWithNavigation(from: c, to: d)
          .copyWith(navigationIndex: 1)
          .copyWithNavigation(from: b, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, b, c]);
      expect(state.navigationIndex, 2);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test('a jump removes the forward comment at its old recorded offset', () {
      const NavigationAnchor shiftedC = NavigationAnchor(
        itemId: 3,
        alignment: -0.2,
      );
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: shiftedC)
          .copyWithNavigation(from: shiftedC, to: d)
          .copyWith(navigationIndex: 1)
          .copyWithNavigation(from: b, to: c);

      expect(state.navigationStack, <NavigationAnchor>[a, b, c]);
      expect(state.navigationIndex, 2);
      expect(state.canNavigateForward, isFalse);
    });

    test('a returning origin preserves backward stops and clears forward', () {
      const NavigationAnchor scrolledA = NavigationAnchor(
        itemId: 1,
        alignment: -0.1,
      );
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 1)
          .copyWithNavigation(from: scrolledA, to: d);

      expect(state.navigationStack, <NavigationAnchor>[a, b, scrolledA, d]);
      expect(state.navigationIndex, 3);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test(
      'each jump after Back discards only positions ahead of its origin',
      () {
        const NavigationAnchor e = NavigationAnchor(itemId: 5, alignment: 0.15);
        const NavigationAnchor f = NavigationAnchor(itemId: 6, alignment: 0.15);
        state = state
            .copyWithNavigation(from: a, to: b)
            .copyWithNavigation(from: b, to: c)
            .copyWith(navigationIndex: 1)
            .copyWithNavigation(from: b, to: d);
        expect(state.navigationStack, <NavigationAnchor>[a, b, d]);

        state = state
            .copyWith(navigationIndex: 1)
            .copyWithNavigation(from: b, to: e);
        expect(state.navigationStack, <NavigationAnchor>[a, b, e]);

        state = state
            .copyWith(navigationIndex: 0)
            .copyWithNavigation(from: a, to: f);
        expect(state.navigationStack, <NavigationAnchor>[a, f]);
        expect(state.navigationIndex, 1);
        expect(state.canNavigateBack, isTrue);
        expect(state.canNavigateForward, isFalse);
      },
    );

    test('a jump to the current position is not recorded', () {
      state = state.copyWithNavigation(from: a, to: a);

      expect(state.navigationStack, isEmpty);
    });

    test('a jump to the current position still clears forward history', () {
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 1);
      state = state.copyWithNavigation(from: b, to: b);

      expect(state.navigationStack, <NavigationAnchor>[a, b]);
      expect(state.navigationIndex, 1);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test(
      'a same-comment jump keeps its source offset and clears forward history',
      () {
        const NavigationAnchor shiftedB = NavigationAnchor(
          itemId: 2,
          alignment: -0.2,
        );
        state = state
            .copyWithNavigation(from: a, to: b)
            .copyWithNavigation(from: b, to: c)
            .copyWith(navigationIndex: 1)
            .copyWithNavigation(from: shiftedB, to: b);

        expect(state.navigationStack, <NavigationAnchor>[a, shiftedB, b]);
        expect(state.navigationIndex, 2);
        expect(state.canNavigateForward, isFalse);
      },
    );

    test('tiny offset drift does not add a duplicate history stop', () {
      const NavigationAnchor nearB = NavigationAnchor(
        itemId: 2,
        alignment: 0.15000000001,
      );
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 1)
          .copyWithNavigation(from: nearB, to: b);

      expect(state.navigationStack, <NavigationAnchor>[a, b]);
      expect(state.navigationIndex, 1);
      expect(state.canNavigateForward, isFalse);
    });

    test('different offsets within the current comment remain separate', () {
      const NavigationAnchor shiftedB = NavigationAnchor(
        itemId: 2,
        alignment: -0.2,
      );
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(to: shiftedB);

      expect(state.navigationStack, <NavigationAnchor>[a, b, shiftedB]);
      expect(state.navigationIndex, 2);
    });

    test('a jump from an unknown position only records the destination', () {
      state = state.copyWithNavigation(to: b);

      expect(state.navigationStack, <NavigationAnchor>[b]);
      expect(state.canNavigateBack, isFalse);
    });

    test('a jump from an unknown origin after Back clears forward history', () {
      state = state
          .copyWithNavigation(from: a, to: b)
          .copyWithNavigation(from: b, to: c)
          .copyWith(navigationIndex: 0)
          .copyWithNavigation(to: d);

      expect(state.navigationStack, <NavigationAnchor>[a, d]);
      expect(state.navigationIndex, 1);
      expect(state.canNavigateBack, isTrue);
      expect(state.canNavigateForward, isFalse);
    });

    test('retains every position beyond the former 50-position limit', () {
      const int jumps = 100;
      for (int i = 0; i < jumps; i++) {
        state = state.copyWithNavigation(
          from: NavigationAnchor(itemId: i, alignment: 0),
          to: NavigationAnchor(itemId: i + 1, alignment: 0.15),
        );
      }

      expect(state.navigationStack, hasLength(jumps + 1));
      expect(state.navigationStack.first.itemId, 0);
      expect(state.navigationStack.last.itemId, jumps);
      expect(
        state.navigationStack.map((NavigationAnchor anchor) => anchor.itemId),
        List<int>.generate(jumps + 1, (int index) => index),
      );
      expect(state.navigationIndex, state.navigationStack.length - 1);
    });
  });
}
