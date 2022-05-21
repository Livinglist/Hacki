import 'dart:io';

import 'package:hacki/models/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

/// [SembastRepository] is for storing stories and comments for faster loading.
/// It's using Sembast as its database which is being stored in doc directory.
class SembastRepository {
  SembastRepository({Database? database}) {
    if (database == null) {
      initializeDatabase();
    } else {
      _database = database;
    }
  }

  Database? _database;
  List<int>? _idsOfCommentsRepliedToMe;

  static const String _cachedCommentsKey = 'cachedComments';
  static const String _commentsKey = 'comments';
  static const String _idsOfCommentsRepliedToMeKey = 'idsOfCommentsRepliedToMe';

  Future<Database> initializeDatabase() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final String dbPath = join(dir.path, 'hacki.db');
    final DatabaseFactory dbFactory = databaseFactoryIo;
    final Database db = await dbFactory.openDatabase(dbPath);
    _database = db;
    return db;
  }

  //#region Cached comments for time machine feature.
  Future<Map<String, Object?>> cacheComment(Comment comment) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_cachedCommentsKey);
    return store.record(comment.id).put(db, comment.toJson());
  }

  Future<Comment?> getCachedComment({required int id}) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_cachedCommentsKey);
    final RecordSnapshot<int, Map<String, Object?>>? snapshot =
        await store.record(id).getSnapshot(db);
    if (snapshot != null) {
      final Comment comment = Comment.fromJson(snapshot.value);
      return comment;
    } else {
      return null;
    }
  }

  Future<int> deleteAllCachedComments() async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_cachedCommentsKey);
    return store.delete(db);
  }

  //#endregion

  //#region Saved comments for notification feature.
  Future<Map<String, Object?>> saveComment(Comment comment) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_commentsKey);
    return store.record(comment.id).put(db, comment.toJson());
  }

  Future<void> saveComments(List<Comment> comments) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_commentsKey);

    return db.transaction((Transaction txn) async {
      for (final Comment cmt in comments) {
        await store.record(cmt.id).put(txn, cmt.toJson());
      }
    });
  }

  Future<List<int>> getIdsOfCommentsRepliedToMe() async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<dynamic, dynamic> store = StoreRef<dynamic, dynamic>.main();
    final RecordSnapshot<dynamic, dynamic>? snapshot =
        await store.record(_idsOfCommentsRepliedToMeKey).getSnapshot(db);
    final List<int> repliedToMe =
        (snapshot?.value as List<dynamic>? ?? <int>[]).cast<int>();
    _idsOfCommentsRepliedToMe = repliedToMe;
    return repliedToMe;
  }

  Future<void> updateIdsOfCommentsRepliedToMe(int id) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<dynamic, dynamic> store = StoreRef<dynamic, dynamic>.main();
    late final List<int> list;

    if (_idsOfCommentsRepliedToMe == null) {
      final RecordSnapshot<dynamic, dynamic>? snapshot =
          await store.record(_idsOfCommentsRepliedToMeKey).getSnapshot(db);
      list = (snapshot?.value as List<dynamic>? ?? <int>[]).cast<int>();
      _idsOfCommentsRepliedToMe = list;
    } else {
      list = _idsOfCommentsRepliedToMe!;
    }

    final List<int> updatedList =
        (<int>{id, ...list}.toList()..sort()).reversed.toList();
    _idsOfCommentsRepliedToMe = updatedList;

    return store.record(_idsOfCommentsRepliedToMeKey).put(db, updatedList);
  }

  Future<Comment?> getComment({required int id}) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_commentsKey);
    final RecordSnapshot<int, Map<String, Object?>>? snapshot =
        await store.record(id).getSnapshot(db);
    if (snapshot != null) {
      final Comment comment = Comment.fromJson(snapshot.value);
      return comment;
    } else {
      return null;
    }
  }

  Future<List<Comment>> getComments({required List<int> ids}) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, Map<String, Object?>> store =
        intMapStoreFactory.store(_commentsKey);
    final List<Comment> comments = <Comment>[];

    await db.transaction((Transaction txn) async {
      for (final int id in ids) {
        final RecordSnapshot<int, Map<String, Object?>>? snapshot =
            await store.record(id).getSnapshot(txn);
        if (snapshot != null) {
          final Comment comment = Comment.fromJson(snapshot.value);
          comments.add(comment);
        }
      }
    });

    return comments;
  }

  Future<List<dynamic>> updateKidsOf({
    required int id,
    required List<int> kids,
  }) async {
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, List<dynamic>> store =
        StoreRef<int, List<dynamic>>.main();
    return store.record(id).put(db, kids);
  }

  Future<List<int>?> kids({required int of}) async {
    final int itemId = of;
    final Database db = _database ?? await initializeDatabase();
    final StoreRef<int, List<dynamic>> store =
        StoreRef<int, List<dynamic>>.main();
    final RecordSnapshot<int, List<dynamic>>? snapshot =
        await store.record(itemId).getSnapshot(db);
    final List<int>? kids = snapshot?.value.cast<int>();
    return kids;
  }

  //#endregion

  Future<FileSystemEntity> deleteAll() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final String dbPath = join(dir.path, 'hacki.db');
    return File(dbPath).delete();
  }
}
