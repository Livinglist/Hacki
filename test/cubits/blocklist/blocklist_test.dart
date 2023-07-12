import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferenceRepository extends Mock implements PreferenceRepository {}

void main() {
  final MockPreferenceRepository mockPreferenceRepository =
      MockPreferenceRepository();
  late BlocklistCubit blocklistCubit;
  late List<String> blocklist;
  const String username = 'username';

  when(() => mockPreferenceRepository.blocklist)
      .thenAnswer((_) => Future<List<String>>.value(<String>[]));
  when(() => mockPreferenceRepository.updateBlocklist(any()))
      .thenAnswer((_) => Future<void>.value());

  setUpAll(
    () => <void>{
      blocklistCubit =
          BlocklistCubit(storageRepository: mockPreferenceRepository)
    },
  );

  group('Blocklist Test', () {
    test('initial state is BlocklistState.init', () async {
      blocklist = await mockPreferenceRepository.blocklist;
      expect(BlocklistState(blocklist: blocklist), BlocklistState.init());
    });

    test('add to blocklist', () async {
      blocklist = await mockPreferenceRepository.blocklist
        ..add(username);
      when(() => mockPreferenceRepository.blocklist)
          .thenAnswer((_) => Future<List<String>>.value(blocklist));
      blocklistCubit.addToBlocklist(username);
      expect(blocklistCubit.state, BlocklistState(blocklist: blocklist));
    });

    test('remove to blocklist', () async {
      blocklist = await mockPreferenceRepository.blocklist
        ..remove(username);
      blocklistCubit.removeFromBlocklist(username);
      expect(blocklistCubit.state, BlocklistState(blocklist: blocklist));
    });
  });
}
