import 'dart:async';

import 'package:favicon/favicon.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/sembast_repository.dart';
import 'package:logger/logger.dart';

class FaviconRepository {
  FaviconRepository({
    SembastRepository? sembastRepository,
    Logger? logger,
  })  : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _logger = logger ?? locator.get<Logger>();

  final SembastRepository _sembastRepository;
  final Logger _logger;

  static final Map<String, String?> _cache = <String, String?>{};
  static final Set<String> _requested = <String>{};

  Future<String?> getFaviconUrl(String url) async {
    if (url.isEmpty) return null;
    final Uri uri = Uri.parse(url);
    final String host = uri.host;

    /// Prevent duplicate request.
    if (_requested.contains(host)) {
      return null;
    } else {
      _requested.add(url);
    }

    if (_cache.containsKey(host)) {
      return _cache[host];
    } else {
      String? faviconUrl =
          await _sembastRepository.getCachedFavicon(host: host);
      if (faviconUrl != null) {
        _cache[host] = faviconUrl;
        _logger.d('cached favicon url ($faviconUrl) fetched for $url');
        return faviconUrl;
      } else {
        _logger.d('fetching favicon for $url');
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
        _logger.d('favicon url ($faviconUrl) fetched for $url');
        return faviconUrl;
      }
    }
  }

  static Future<String?> _fetchFaviconUrl(String url) async {
    final Favicon? result = await FaviconFinder.getBest(url);
    return result?.url;
  }
}
