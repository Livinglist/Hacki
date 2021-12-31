import 'package:url_launcher/url_launcher.dart';

class LinkUtil {
  static void launch(String link) {
    final url = Uri.encodeFull(link);
    canLaunch(url).then((val) {
      if (val) {
        launch(url);
      }
    });
  }
}
