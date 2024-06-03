import 'dart:async';

import 'package:favicon/favicon.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/sembast_repository.dart';

class FaviconRepository {
  FaviconRepository({SembastRepository? sembastRepository})
      : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>();

  final SembastRepository _sembastRepository;

  static final Map<String, String?> _cache = <String, String?>{};

  Future<String?> getFaviconUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final String host = uri.host;
    if (_cache.containsKey(host)) {
      return _cache[host];
    } else {
      String? faviconUrl =
          await _sembastRepository.getCachedFavicon(host: host);
      if (faviconUrl != null) {
        _cache[host] = faviconUrl;
        return faviconUrl;
      } else {
        faviconUrl = await compute(_fetchFaviconUrl, url);
        _cache[host] = faviconUrl;
        if (faviconUrl != null) {
          unawaited(
            _sembastRepository.cacheFavicon(
              host: host,
              faviconUrl: faviconUrl,
            ),
          );
        }
        return faviconUrl;
      }
    }
  }

  static Future<String?> _fetchFaviconUrl(String url) async {
    final Favicon? result = await FaviconFinder.getBest(url);
    return result?.url;
  }
}
