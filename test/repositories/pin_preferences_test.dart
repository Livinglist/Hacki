import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int storyId = 100;
  const int commentId = 200;
  late SharedPreferences prefs;
  late PreferenceRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pinnedStoriesIds': <String>[storyId.toString()],
    });
    prefs = await SharedPreferences.getInstance();
    repository = PreferenceRepository(
      prefs: Future<SharedPreferences>.value(prefs),
    );
  });

  test('reads existing story pins from the original preference key', () async {
    expect(await repository.pinnedItemsIds, <int>[storyId]);
  });

  test('persists mixed story and comment IDs under the original key', () async {
    await repository.updatePinnedItemsIds(<int>[commentId, storyId]);

    expect(prefs.getStringList('pinnedStoriesIds'), <String>[
      commentId.toString(),
      storyId.toString(),
    ]);
    expect(await repository.pinnedItemsIds, <int>[commentId, storyId]);
    expect(prefs.containsKey('pinnedItemsIds'), isFalse);
  });
}
