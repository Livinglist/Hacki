import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:workmanager/workmanager.dart';

void fetcherCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) {
    Fetcher.fetchReplies();

    return Future<bool>.value(true);
  });
}

abstract class Fetcher {
  static const int _subscriptionUpperLimit = 15;

  static Future<void> fetchReplies() async {
    final AuthRepository authRepository = AuthRepository();
    final PreferenceRepository preferenceRepository = PreferenceRepository();
    final StoriesRepository storiesRepository = StoriesRepository();
    final SembastRepository sembastRepository = SembastRepository();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final String? username = await authRepository.username;

    if (username == null || username.isEmpty) return;

    final List<int> unreadCommentsIds =
        await preferenceRepository.unreadCommentsIds;

    await storiesRepository
        .fetchSubmitted(of: username)
        .then((List<int>? submittedItems) async {
      if (submittedItems != null) {
        final List<int> subscribedItems = submittedItems.sublist(
          0,
          min(_subscriptionUpperLimit, submittedItems.length),
        );

        for (final int id in subscribedItems) {
          await storiesRepository.fetchItemBy(id: id).then((Item? item) async {
            final List<int> kids = item?.kids ?? <int>[];
            final List<int> previousKids =
                (await sembastRepository.kids(of: id)) ?? <int>[];

            await sembastRepository.updateKidsOf(id: id, kids: kids);

            final Set<int> diff =
                <int>{...kids}.difference(<int>{...previousKids});

            Comment? newReply;

            if (diff.isNotEmpty) {
              for (final int newCommentId in diff) {
                await preferenceRepository.updateUnreadCommentsIds(
                  <int>[
                    newCommentId,
                    ...unreadCommentsIds,
                  ]..sort((int lhs, int rhs) => rhs.compareTo(lhs)),
                );
                await storiesRepository
                    .fetchCommentBy(id: newCommentId)
                    .then((Comment? comment) {
                  if (comment != null && !comment.dead && !comment.deleted) {
                    sembastRepository
                      ..saveComment(comment)
                      ..updateIdsOfCommentsRepliedToMe(comment.id);

                    newReply = comment;
                  }
                });
              }
            }

            if (newReply != null) {
              // Push notification for new unread reply.
              await flutterLocalNotificationsPlugin.show(
                newReply?.id ?? 0,
                'You have a new reply!',
                '${newReply?.by}: ${newReply?.text}',
                const NotificationDetails(
                  iOS: IOSNotificationDetails(
                    presentBadge: false,
                    threadIdentifier: 'hacki',
                  ),
                ),
                payload: '${newReply?.id}',
              );
            }
          });
        }
      }
    });
  }

  static void onSelectNotification(String? payload) {}
}
