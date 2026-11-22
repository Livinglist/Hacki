import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockPreferenceRepository preferenceRepository;
  late MockHackerNewsRepository hackerNewsRepository;
  PinCubit? cubit;

  final Story story = Story.fromJson(const <String, dynamic>{
    'id': 100,
    'type': 'story',
    'title': 'A pinned story',
    'by': 'alice',
    'time': 0,
  });
  final Comment comment = Comment.fromJson(const <String, dynamic>{
    'id': 200,
    'type': 'comment',
    'text': 'A pinned comment thread',
    'parent': 100,
    'by': 'bob',
    'time': 0,
  });

  Future<PinCubit> createCubit() async {
    final PinCubit result = PinCubit(
      preferenceRepository: preferenceRepository,
      hackerNewsRepository: hackerNewsRepository,
    );
    cubit = result;
    await pumpEventQueue();
    return result;
  }

  setUp(() {
    preferenceRepository = MockPreferenceRepository();
    hackerNewsRepository = MockHackerNewsRepository();
    when(
      () => preferenceRepository.pinnedItemsIds,
    ).thenAnswer((_) async => <int>[]);
    when(
      () => preferenceRepository.updatePinnedItemsIds(any()),
    ).thenAnswer((_) async {});
    when(
      () => hackerNewsRepository.fetchItemsStream(ids: any(named: 'ids')),
    ).thenAnswer((_) => const Stream<Item>.empty());
  });

  tearDown(() async {
    await cubit?.close();
    cubit = null;
  });

  test('restores saved stories and comment threads in pin order', () async {
    when(
      () => preferenceRepository.pinnedItemsIds,
    ).thenAnswer((_) async => <int>[story.id, comment.id]);
    when(
      () => hackerNewsRepository.fetchItemsStream(
        ids: <int>[story.id, comment.id],
      ),
    ).thenAnswer((_) => Stream<Item>.fromIterable(<Item>[story, comment]));

    final PinCubit pinCubit = await createCubit();

    expect(pinCubit.state.pinnedItemsIds, <int>[story.id, comment.id]);
    expect(pinCubit.state.pinnedItems, <Item>[story, comment]);
    verify(
      () => hackerNewsRepository.fetchItemsStream(
        ids: <int>[story.id, comment.id],
      ),
    ).called(1);
    verifyNever(() => preferenceRepository.updatePinnedItemsIds(any()));
  });

  test('pins and unpins a comment thread and persists its ID', () async {
    final PinCubit pinCubit = await createCubit();
    int completed = 0;

    pinCubit.pinItem(comment, onDone: () => completed++);

    expect(pinCubit.state.pinnedItemsIds, <int>[comment.id]);
    expect(pinCubit.state.pinnedItems, <Item>[comment]);
    expect(completed, 1);
    verify(
      () => preferenceRepository.updatePinnedItemsIds(<int>[comment.id]),
    ).called(1);

    pinCubit.unpinItem(comment, onDone: () => completed++);

    expect(pinCubit.state.pinnedItemsIds, isEmpty);
    expect(pinCubit.state.pinnedItems, isEmpty);
    expect(completed, 2);
    verify(() => preferenceRepository.updatePinnedItemsIds(<int>[])).called(1);
  });

  test(
    'adds a comment ahead of existing story pins without duplicates',
    () async {
      final PinCubit pinCubit = await createCubit();
      pinCubit
        ..pinItem(story)
        ..pinItem(comment);
      clearInteractions(preferenceRepository);
      int completed = 0;

      pinCubit.pinItem(comment, onDone: () => completed++);

      expect(pinCubit.state.pinnedItemsIds, <int>[comment.id, story.id]);
      expect(pinCubit.state.pinnedItems, <Item>[comment, story]);
      expect(completed, 0);
      verifyNever(() => preferenceRepository.updatePinnedItemsIds(any()));
    },
  );

  test('unpins an updated instance of the same comment by ID', () async {
    final PinCubit pinCubit = await createCubit();
    pinCubit
      ..pinItem(story)
      ..pinItem(comment);
    final Comment updatedComment = Comment.fromJson(<String, dynamic>{
      ...comment.toJson(),
      'text': 'Edited comment text',
      'kids': const <int>[201],
    });

    pinCubit.unpinItem(updatedComment);

    expect(pinCubit.state.pinnedItemsIds, <int>[story.id]);
    expect(pinCubit.state.pinnedItems, <Item>[story]);
    verify(
      () => preferenceRepository.updatePinnedItemsIds(<int>[story.id]),
    ).called(2);
  });

  test(
    'removes all story and comment pins and persists an empty list',
    () async {
      final PinCubit pinCubit = await createCubit();
      pinCubit
        ..pinItem(story)
        ..pinItem(comment)
        ..removeAll();

      expect(pinCubit.state.pinnedItemsIds, isEmpty);
      expect(pinCubit.state.pinnedItems, isEmpty);
      verify(
        () => preferenceRepository.updatePinnedItemsIds(<int>[]),
      ).called(1);
    },
  );

  test('ignores a late fetched item after its pin has been removed', () async {
    final StreamController<Item> controller = StreamController<Item>();
    addTearDown(controller.close);
    when(
      () => preferenceRepository.pinnedItemsIds,
    ).thenAnswer((_) async => <int>[story.id, comment.id]);
    when(
      () => hackerNewsRepository.fetchItemsStream(ids: any(named: 'ids')),
    ).thenAnswer((_) => controller.stream);
    final PinCubit pinCubit = await createCubit();

    pinCubit.unpinItem(comment);
    controller
      ..add(story)
      ..add(comment);
    await pumpEventQueue();

    expect(pinCubit.state.pinnedItemsIds, <int>[story.id]);
    expect(pinCubit.state.pinnedItems, <Item>[story]);
  });
}
