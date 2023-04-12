import 'dart:io';

import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  void requestReview() {
    if (Platform.isIOS) {
      InAppReview.instance.requestReview();
    }
  }
}
