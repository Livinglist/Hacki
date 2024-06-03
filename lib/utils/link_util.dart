import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart'
    show ItemScreen, ItemScreenArgs, WebViewScreen;
import 'package:url_launcher/url_launcher.dart';

abstract class LinkUtil {
  static final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  static void launchInExternalBrowser(
    String link,
  ) {
    final Uri uri = Uri.parse(link);
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static void launch(
    String link,
    BuildContext context, {
    bool useReader = false,
    bool offlineReading = false,
    bool useHackiForHnLink = true,
  }) {
    if (offlineReading) {
      locator
          .get<OfflineRepository>()
          .hasCachedWebPage(url: link)
          .then((bool cached) {
        if (cached) {
          router.push(
            '/${WebViewScreen.routeName}',
            extra: link,
          );
        }
      });

      return;
    }

    if (useHackiForHnLink && link.isStoryLink) {
      final int? id = link.itemId;
      if (id != null) {
        locator
            .get<HackerNewsRepository>()
            .fetchItem(id: id)
            .then((Item? item) {
          if (item != null) {
            router.push(
              '/${ItemScreen.routeName}',
              extra: ItemScreenArgs(item: item),
            );
          }
        });
        return;
      }
    }

    final Uri uri = Uri.parse(link);

    canLaunchUrl(uri).then((bool val) {
      if (val) {
        if (link.contains('http')) {
          if (Platform.isAndroid &&
              context.read<PreferenceCubit>().state.customTabEnabled == false) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            final Color primaryColor = Theme.of(context).colorScheme.primary;
            _browser
                .open(
                  url: WebUri.uri(uri),
                  settings: Platform.isAndroid
                      ? ChromeSafariBrowserSettings(
                          toolbarBackgroundColor: primaryColor,
                        )
                      : ChromeSafariBrowserSettings(
                          entersReaderIfAvailable: useReader,
                          preferredControlTintColor: primaryColor,
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
