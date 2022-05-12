import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtil {
  static final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  static void launchUrl(String link, {bool useReader = false}) {
    Uri rinseLink(String link) {
      if (link.contains(')')) {
        final RegExp regex = RegExp(r'\).*$');
        final String match = regex.stringMatch(link) ?? '';
        return Uri.parse(link.replaceAll(match, ''));
      }

      return Uri.parse(link);
    }

    final Uri uri = rinseLink(link);
    canLaunchUrl(uri).then((bool val) {
      if (val) {
        _browser.open(
          url: uri,
          options: ChromeSafariBrowserClassOptions(
            ios: IOSSafariOptions(
              entersReaderIfAvailable: useReader,
              preferredControlTintColor: Colors.orange,
            ),
          ),
        );
      }
    });
  }
}
