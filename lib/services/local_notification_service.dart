import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';

class LocalNotificationService {
  Future<void> pushForNewReply(Comment newReply, int storyId) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final Map<String, int> payloadJson = <String, int>{
      'commentId': newReply.id,
      'storyId': storyId,
    };
    final String payload = jsonEncode(payloadJson);

    return flutterLocalNotificationsPlugin.show(
      newReply.id,
      'You have a new reply! ${Constants.happyFace}',
      '${newReply.by}: ${newReply.text}',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentBadge: false,
          threadIdentifier: 'hacki',
        ),
      ),
      payload: payload,
    );
  }
}
