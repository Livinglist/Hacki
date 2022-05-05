import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/html_util.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:path_provider_ios/path_provider_ios.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:workmanager/workmanager.dart';

void fetcherCallbackDispatcher() {
  Workmanager()
      .executeTask((String task, Map<String, dynamic>? inputData) async {
    if (Platform.isAndroid) {
      PathProviderAndroid.registerWith();
      SharedPreferencesAndroid.registerWith();
    }
    if (Platform.isIOS) {
      PathProviderIOS.registerWith();
      SharedPreferencesIOS.registerWith();
    }

    await Fetcher.fetchReplies();

    return Future<bool>.value(true);
  });
}

abstract class Fetcher {
  static const int _subscriptionUpperLimit = 15;

  static Future<void> fetchReplies() async {
    final PreferenceRepository preferenceRepository = PreferenceRepository();
    final AuthRepository authRepository = AuthRepository(
      preferenceRepository: preferenceRepository,
    );
    final StoriesRepository storiesRepository = StoriesRepository();
    final SembastRepository sembastRepository = SembastRepository();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final String happyFace = Constants.happyFaces.pickRandomly()!;
    final String? username = await authRepository.username;
    final List<int> unreadIds = await preferenceRepository.unreadCommentsIds;

    if (username == null || username.isEmpty) return;

    Comment? newReply;

    await storiesRepository
        .fetchSubmitted(of: username)
        .then((List<int>? submittedItems) async {
      if (submittedItems != null) {
        final List<int> subscribedItems = submittedItems.sublist(
          0,
          min(_subscriptionUpperLimit, submittedItems.length),
        );

        for (final int id in subscribedItems) {
          await storiesRepository
              .fetchRawItemBy(id: id)
              .then((Item? item) async {
            final List<int> kids = item?.kids ?? <int>[];
            final List<int> previousKids =
                (await sembastRepository.kids(of: id)) ?? <int>[];

            await sembastRepository.updateKidsOf(id: id, kids: kids);

            final Set<int> diff =
                <int>{...kids}.difference(<int>{...previousKids});

            if (diff.isNotEmpty) {
              for (final int newCommentId in diff) {
                if (unreadIds.contains(newCommentId)) continue;

                await storiesRepository
                    .fetchRawCommentBy(id: newCommentId)
                    .then((Comment? comment) async {
                  final bool hasPushedBefore =
                      await preferenceRepository.hasPushed(newReply!.id);

                  if (comment != null && !comment.dead && !comment.deleted) {
                    await sembastRepository.saveComment(comment);
                    await sembastRepository.updateIdsOfCommentsRepliedToMe(
                      comment.id,
                    );

                    if (!hasPushedBefore) {
                      newReply = comment;
                    }
                  }
                });

                if (newReply != null) break;
              }
            }
          });

          if (newReply != null) break;
        }
      }
    });

    // Push notification for new unread reply that has not been
    // pushed before.
    if (newReply != null) {
      final Story? story =
          await storiesRepository.fetchRawParentStory(id: newReply!.id);
      final String text = HtmlUtil.parseHtml(newReply!.text);

      if (story != null) {
        final Map<String, int> payloadJson = <String, int>{
          'commentId': newReply!.id,
          'storyId': story.id,
        };
        final String payload = jsonEncode(payloadJson);

        await preferenceRepository.updateHasPushed(newReply!.id);

        await flutterLocalNotificationsPlugin.show(
          newReply?.id ?? 0,
          'You have a new reply! $happyFace',
          '${newReply?.by}: $text',
          const NotificationDetails(
            iOS: IOSNotificationDetails(
              presentBadge: false,
              threadIdentifier: 'hacki',
            ),
          ),
          payload: payload,
        );
      }
    }
  }
}
