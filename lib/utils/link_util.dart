import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkUtil {
  static final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  static void launchUrl(String link, {bool useReader = false}) {
    String rinseLink(String link) {
      if (link.contains(')')) {
        final RegExp regex = RegExp(r'\).*$');
        final String match = regex.stringMatch(link) ?? '';
        return link.replaceAll(match, '');
      }

      return link;
    }

    canLaunch(link).then((bool val) {
      if (val) {
        final String rinsedLink = rinseLink(link);
        _browser.open(
          url: Uri.parse(rinsedLink),
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
