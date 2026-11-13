import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

void main() {
  late _MockPostRepository postRepository;

  setUp(() => postRepository = _MockPostRepository());

  group('PostCubit', () {
    blocTest<PostCubit, PostState>(
      'reports what was posted and where once a reply goes through',
      setUp: () => when(
        () => postRepository.comment(parentId: 1, text: 'hello'),
      ).thenAnswer((_) async => true),
      build: () => PostCubit(postRepository: postRepository),
      act: (PostCubit cubit) => cubit.post(text: 'hello', to: 1),
      expect: () => const <PostState>[
        PostState(status: Status.inProgress),
        PostState(status: Status.success, parentId: 1, text: 'hello'),
      ],
    );

    blocTest<PostCubit, PostState>(
      'reports what was edited once an edit goes through',
      setUp: () => when(
        () => postRepository.edit(id: 2, text: 'fixed'),
      ).thenAnswer((_) async => true),
      build: () => PostCubit(postRepository: postRepository),
      act: (PostCubit cubit) => cubit.edit(text: 'fixed', id: 2),
      expect: () => const <PostState>[
        PostState(status: Status.inProgress),
        PostState(status: Status.success, editedId: 2, text: 'fixed'),
      ],
    );

    blocTest<PostCubit, PostState>(
      'reports nothing posted when a reply fails',
      setUp: () => when(
        () => postRepository.comment(parentId: 1, text: 'hello'),
      ).thenAnswer((_) async => false),
      build: () => PostCubit(postRepository: postRepository),
      act: (PostCubit cubit) => cubit.post(text: 'hello', to: 1),
      expect: () => const <PostState>[
        PostState(status: Status.inProgress),
        PostState(status: Status.failure),
      ],
    );

    blocTest<PostCubit, PostState>(
      'forgets what was posted on reset',
      setUp: () => when(
        () => postRepository.comment(parentId: 1, text: 'hello'),
      ).thenAnswer((_) async => true),
      build: () => PostCubit(postRepository: postRepository),
      act: (PostCubit cubit) async {
        await cubit.post(text: 'hello', to: 1);
        cubit.reset();
      },
      skip: 2,
      expect: () => const <PostState>[PostState.init()],
    );
  });
}
