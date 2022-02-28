import 'package:hive/hive.dart';

class CacheRepository {
  CacheRepository({Future<Box<bool>>? box})
      : _box = box ?? Hive.openBox<bool>(_boxName);

  static const _boxName = 'cacheBox';
  final Future<Box<bool>> _box;

  Future<bool> wasRead({required int id}) async {
    final box = await _box;
    final val = box.get(id.toString());
    return val != null;
  }

  Future<void> cacheReadStory({required int id}) async {
    final box = await _box;
    return box.put(id.toString(), true);
  }

  Future<List<int>> getAllReadStoriesIds() async {
    final box = await _box;
    final allReads = box.keys.cast<String>().map(int.parse).toList();
    return allReads;
  }

  Future<int> deleteAll() async {
    final box = await _box;
    return box.clear();
  }
}
