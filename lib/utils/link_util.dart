import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hacki/main.dart';
import 'package:hacki/screens/screens.dart' show WebViewScreen;
import 'package:url_launcher/url_launcher.dart';

abstract class LinkUtil {
  static final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  static void launch(
    String link, {
    bool useReader = false,
    bool offlineReading = false,
  }) {
    if (offlineReading) {
      HackiApp.navigatorKey.currentState?.push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => WebViewScreen(url: link),
        ),
      );
      return;
    }

    Uri rinseLink(String link) {
      final RegExp regex = RegExp(r'\)|].*$');
      if (!link.contains('en.wikipedia.org') && link.contains(regex)) {
        final String match = regex.stringMatch(link) ?? '';
        return Uri.parse(link.replaceAll(match, ''));
      }

      return Uri.parse(link);
    }

    final Uri uri = rinseLink(link);
    canLaunchUrl(uri).then((bool val) {
      if (val) {
        if (link.contains('http')) {
          if (Platform.isAndroid) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _browser
                .open(
                  url: uri,
                  options: ChromeSafariBrowserClassOptions(
                    ios: IOSSafariOptions(
                      entersReaderIfAvailable: useReader,
                      preferredControlTintColor: Colors.orange,
                    ),
                  ),
                )
                .onError((_, __) => launchUrl(uri));
          }
        } else {
          launchUrl(uri);
        }
      }
    });
  }
}
