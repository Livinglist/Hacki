import 'package:collection/collection.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/extensions/loggable.dart';
import 'package:hacki/models/models.dart';
import 'package:hive/hive.dart';

/// [HistoryRepository] is for persisting IDs of read stories.
class HistoryRepository with Loggable {
  HistoryRepository({Future<Box<int>>? idBox})
    : _box = idBox ?? Hive.openBox<int>(_boxName) {
    initialize();
  }

  static const String _boxName = 'readStoryIds';
  static const int _maxLength = 1_000;
  final Future<Box<int>> _box;
  Status _status = .idle;

  final Set<int> _readIds = <int>{};

  Future<void> initialize() async {
    if (_status == .idle) {
      final Iterable<int> res = await loadAll();
      _readIds.addAll(res);
      _status = .success;
    }
  }

  Future<bool> hasRead(int storyId) async {
    if (_readIds.isEmpty) {
      final Box<int> box = await _box;
      return box.containsKey(storyId);
    } else {
      return _readIds.contains(storyId);
    }
  }

  Future<void> saveReadStoryId(int storyId) async {
    _readIds.add(storyId);
    final Box<int> box = await _box;
    return box.put(storyId, storyId);
  }

  Future<void> removeReadStoryId(int storyId) async {
    _readIds.remove(storyId);
    final Box<int> box = await _box;
    return box.delete(storyId);
  }

  Future<void> clearAllReadStoryIds() async {
    _readIds.clear();
    final Box<int> box = await _box;
    await box.clear();
  }

  Future<Iterable<int>> loadAll() async {
    final Box<int> box = await _box;
    final Iterable<int> results = box.keys.cast<int>();

    if (results.length > _maxLength) {
      logInfo('''read ids exceeds limit: ${results.length}''');
      logInfo('''read ids are: $results''');
      final List<int> orderedStoryIds = results.sorted(
        (int lhs, int rhs) => lhs.compareTo(rhs),
      );
      final int end = box.length ~/ 2;
      final List<int> firstHalf = orderedStoryIds.sublist(0, end);
      logInfo('''read ids being removed: ${firstHalf.length}''');
      await box.deleteAll(firstHalf);
    }
    logInfo('''retrieved ${results.length} read ids''');
    return results;
  }

  Future<void> clear() async => (await _box).clear();

  @override
  String get logIdentifier => 'HistoryRepository';
}
