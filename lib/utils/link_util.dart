import 'package:url_launcher/url_launcher.dart';

class LinkUtil {
  static void launchUrl(String link) {
    final url = Uri.encodeFull(link);
    canLaunch(url).then((val) {
      if (val) {
        launch(url);
      }
    });
  }
}
