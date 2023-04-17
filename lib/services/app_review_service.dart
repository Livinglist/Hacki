import 'dart:io';

import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  AppReviewService({PreferenceRepository? preferenceRepository})
      : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>();

  final PreferenceRepository _preferenceRepository;

  static const String _lastRequestTimestampKey = 'lastRequestTimestamp';
  static const int _differenceInDays = 3;

  void requestReview() {
    if (Platform.isIOS) {
      _shouldDisplay().then((bool val) {
        if (val) InAppReview.instance.requestReview();
      });
    }
  }

  Future<bool> _shouldDisplay() async {
    final DateTime now = DateTime.now();
    final int? timestamp =
        await _preferenceRepository.getInt(_lastRequestTimestampKey);

    if (timestamp == null) {
      _preferenceRepository.setInt(
        _lastRequestTimestampKey,
        now.millisecondsSinceEpoch,
      );
      return true;
    }

    final DateTime lastReviewRequest =
        DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    final int difference = now.difference(lastReviewRequest).inDays;

    if (difference >= _differenceInDays) {
      _preferenceRepository.setInt(
        _lastRequestTimestampKey,
        now.millisecondsSinceEpoch,
      );
      return true;
    }

    return false;
  }
}
