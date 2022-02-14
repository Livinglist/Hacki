import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtil {
  static final browser = ChromeSafariBrowser();

  static void launchUrl(String link, {bool useReader = false}) {
    canLaunch(link).then((val) {
      if (val) {
        browser.open(
          url: Uri.parse(link),
          options: ChromeSafariBrowserClassOptions(
            ios: IOSSafariOptions(
                entersReaderIfAvailable: useReader,
                preferredControlTintColor: Colors.orange),
          ),
        );
      }
    });
  }
}
