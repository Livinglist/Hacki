import 'dart:io';

import 'package:hacki/models/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

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

  static const _commentsKey = 'comments';
  static const _idsOfCommentsRepliedToMeKey = 'idsOfCommentsRepliedToMe';

  Future<Database> initializeDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final dbPath = join(dir.path, 'hacki.db');
    final dbFactory = databaseFactoryIo;
    final db = await dbFactory.openDatabase(dbPath);
    _database = db;
    return db;
  }

  Future<Map<String, Object?>> saveComment(Comment comment) async {
    final db = _database ?? await initializeDatabase();
    final store = intMapStoreFactory.store(_commentsKey);
    return store.record(comment.id).put(db, comment.toJson());
  }

  Future<void> saveComments(List<Comment> comments) async {
    final db = _database ?? await initializeDatabase();
    final store = intMapStoreFactory.store(_commentsKey);

    return db.transaction((txn) async {
      for (final cmt in comments) {
        await store.record(cmt.id).put(txn, cmt.toJson());
      }
    });
  }

  Future<List<int>> getIdsOfCommentsRepliedToMe() async {
    final db = _database ?? await initializeDatabase();
    final store = StoreRef<dynamic, dynamic>.main();
    final snapshot =
        await store.record(_idsOfCommentsRepliedToMeKey).getSnapshot(db);
    final repliedToMe = (snapshot?.value as List? ?? <int>[]).cast<int>();
    _idsOfCommentsRepliedToMe = repliedToMe;
    return repliedToMe;
  }

  Future<void> updateIdsOfCommentsRepliedToMe(int id) async {
    final db = _database ?? await initializeDatabase();
    final store = StoreRef<dynamic, dynamic>.main();
    late final List<int> list;

    if (_idsOfCommentsRepliedToMe == null) {
      final snapshot =
          await store.record(_idsOfCommentsRepliedToMeKey).getSnapshot(db);
      list = snapshot?.value as List<int>? ?? <int>[];
      _idsOfCommentsRepliedToMe = list;
    } else {
      list = _idsOfCommentsRepliedToMe!;
    }

    final updatedList = ({id, ...list}.toList()..sort()).reversed.toList();
    _idsOfCommentsRepliedToMe = updatedList;

    return store.record(_idsOfCommentsRepliedToMeKey).put(db, updatedList);
  }

  Future<Comment?> getComment({required int id}) async {
    final db = _database ?? await initializeDatabase();
    final store = intMapStoreFactory.store(_commentsKey);
    final snapshot = await store.record(id).getSnapshot(db);
    if (snapshot != null) {
      final comment = Comment.fromJson(snapshot.value);
      return comment;
    } else {
      return null;
    }
  }

  Future<List<Comment>> getComments({required List<int> ids}) async {
    final db = _database ?? await initializeDatabase();
    final store = intMapStoreFactory.store(_commentsKey);
    final comments = <Comment>[];

    await db.transaction((txn) async {
      for (final id in ids) {
        final snapshot = await store.record(id).getSnapshot(txn);
        if (snapshot != null) {
          final comment = Comment.fromJson(snapshot.value);
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
    final db = _database ?? await initializeDatabase();
    final store = StoreRef<int, List>.main();
    return store.record(id).put(db, kids);
  }

  Future<List<int>?> kids({required int of}) async {
    final itemId = of;
    final db = _database ?? await initializeDatabase();
    final store = StoreRef<int, List>.main();
    final snapshot = await store.record(itemId).getSnapshot(db);
    final kids = snapshot?.value.cast<int>();
    return kids;
  }

  Future<FileSystemEntity> deleteAll() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final dbPath = join(dir.path, 'hacki.db');
    return File(dbPath).delete();
  }
}
