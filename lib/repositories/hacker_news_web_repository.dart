import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/utils.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

/// For fetching anything that cannot be fetched through Hacker News API.
class HackerNewsWebRepository {
  HackerNewsWebRepository({
    RemoteConfigCubit? remoteConfigCubit,
    Dio? dioWithCache,
    Dio? dio,
  })  : _dio = dio ?? Dio(),
        _dioWithCache = dioWithCache ?? Dio()
          ..interceptors.addAll(
            <Interceptor>[
              if (kDebugMode) LoggerInterceptor(),
              CacheInterceptor(),
            ],
          ),
        _remoteConfigCubit =
            remoteConfigCubit ?? locator.get<RemoteConfigCubit>();

  final Dio _dioWithCache;
  final Dio _dio;
  final RemoteConfigCubit _remoteConfigCubit;

  static const Map<String, String> _headers = <String, String>{
    'accept': '*/*',
    'user-agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  };

  static const String _favoritesBaseUrl =
      'https://news.ycombinator.com/favorites?id=';
  static const String _aThingSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing';

  Future<Iterable<int>> fetchFavorites({required String of}) async {
    final bool isOnWifi = await _isOnWifi;
    final String username = of;
    final List<int> allIds = <int>[];
    int page = 1;
    const int maxPage = 2;

    Future<Iterable<int>> fetchIds(int page, {bool isComment = false}) async {
      try {
        final Uri url = Uri.parse(
          '''$_favoritesBaseUrl$username${isComment ? '&comments=t' : ''}&p=$page''',
        );
        final Response<String> response =
            await (isOnWifi ? _dioWithCache : _dio).getUri<String>(url);

        /// Due to rate limiting, we have a short break here.
        await Future<void>.delayed(AppDurations.twoSeconds);

        final Document document = parse(response.data);
        final List<Element> elements =
            document.querySelectorAll(_aThingSelector);
        final Iterable<int> parsedIds =
            elements.map((Element e) => int.tryParse(e.id)).whereNotNull();
        return parsedIds;
      } on DioException catch (e) {
        if (e.response?.statusCode == HttpStatus.forbidden) {
          throw RateLimitedException();
        }
        throw GenericException();
      }
    }

    Iterable<int> ids;
    while (page <= maxPage) {
      ids = await fetchIds(page);
      if (ids.isEmpty) {
        break;
      }
      allIds.addAll(ids);
      page++;
    }

    page = 1;
    while (page <= maxPage) {
      ids = await fetchIds(page, isComment: true);
      if (ids.isEmpty) {
        break;
      }
      allIds.addAll(ids);
      page++;
    }

    return allIds;
  }

  static const String _itemBaseUrl = 'https://news.ycombinator.com/item?id=';

  String get _athingComtrSelector =>
      _remoteConfigCubit.state.athingComtrSelector;

  String get _commentTextSelector =>
      _remoteConfigCubit.state.commentTextSelector;

  String get _commentHeadSelector =>
      _remoteConfigCubit.state.commentHeadSelector;

  String get _commentAgeSelector => _remoteConfigCubit.state.commentAgeSelector;

  String get _commentIndentSelector =>
      _remoteConfigCubit.state.commentIndentSelector;

  Stream<Comment> fetchCommentsStream(Item item) async* {
    final bool isOnWifi = await _isOnWifi;
    final int itemId = item.id;
    final int? descendants = item is Story ? item.descendants : null;
    int parentTextCount = 0;

    Future<Iterable<Element>> fetchElements(int page) async {
      try {
        final Uri url = Uri.parse('$_itemBaseUrl$itemId&p=$page');
        final Options option = Options(
          headers: _headers,
          persistentConnection: true,
        );

        /// Be more conservative while user is on wifi.
        final Response<String> response =
            await (isOnWifi ? _dioWithCache : _dio).getUri<String>(
          url,
          options: option,
        );

        final String data = response.data ?? '';

        if (page == 1) {
          parentTextCount = 'parent'.allMatches(data).length;
        }

        final Document document = parse(data);
        final List<Element> elements =
            document.querySelectorAll(_athingComtrSelector);
        return elements;
      } on DioException catch (e) {
        if (e.response?.statusCode == HttpStatus.forbidden) {
          throw RateLimitedWithFallbackException();
        }
        throw GenericException();
      }
    }

    if (descendants == 0 || item.kids.isEmpty) return;

    final Set<int> fetchedCommentIds = <int>{};
    int page = 1;
    Iterable<Element> elements = await fetchElements(page);
    final Map<int, int> indentToParentId = <int, int>{};

    if (item is Story && item.descendants > 0 && elements.isEmpty) {
      throw PossibleParsingException(itemId: itemId);
    }

    while (elements.isNotEmpty) {
      for (final Element element in elements) {
        /// Get comment id.
        final String cmtIdString = element.attributes['id'] ?? '';
        final int? cmtId = int.tryParse(cmtIdString);

        /// Get comment text.
        final Element? cmtTextElement =
            element.querySelector(_commentTextSelector);
        final String parsedText = await compute(
          _parseCommentTextHtml,
          cmtTextElement?.innerHtml ?? '',
        );

        /// Get comment author.
        final Element? cmtHeadElement =
            element.querySelector(_commentHeadSelector);
        final String? cmtAuthor = cmtHeadElement?.text;

        /// Get comment age.
        final Element? cmtAgeElement =
            element.querySelector(_commentAgeSelector);
        final String? ageString = cmtAgeElement?.attributes['title'];

        final int? timestamp = ageString == null
            ? null
            : DateTime.parse(ageString)
                .copyWith(isUtc: true)
                .millisecondsSinceEpoch;

        /// Get comment indent.
        final Element? cmtIndentElement =
            element.querySelector(_commentIndentSelector);
        final String? indentString = cmtIndentElement?.attributes['indent'];
        final int indent =
            indentString == null ? 0 : (int.tryParse(indentString) ?? 0);

        indentToParentId[indent] = cmtId ?? 0;
        final int parentId = indentToParentId[indent - 1] ?? -1;

        final Comment cmt = Comment(
          id: cmtId ?? 0,
          time: timestamp ?? 0,
          parent: parentId,
          score: 0,
          by: cmtAuthor ?? '',
          text: parsedText,
          kids: const <int>[],
          dead: false,
          deleted: false,
          hidden: false,
          level: indent,
          isFromCache: false,
        );

        /// Skip any comment with no valid id or timestamp.
        if (cmt.id == 0 || timestamp == 0) {
          continue;
        }

        /// Duplicate comment means we are done fetching all the comments.
        if (fetchedCommentIds.contains(cmt.id)) return;

        fetchedCommentIds.add(cmt.id);
        yield cmt;
      }

      /// If we didn't successfully got any comment on first page,
      /// and we are sure there are comments there based on the count of
      /// 'parent' text, then this might be a parsing error and possibly is
      /// caused by HN changing their HTML structure, therefore here we
      /// throw an error so that we can fallback to use API instead.
      if (page == 1 && parentTextCount > 0 && fetchedCommentIds.isEmpty) {
        throw PossibleParsingException(itemId: itemId);
      }

      if (descendants != null && fetchedCommentIds.length >= descendants) {
        return;
      }

      /// Due to rate limiting, we have a short break here.
      await Future<void>.delayed(AppDurations.twoSeconds);

      page++;
      elements = await fetchElements(page);
    }
  }

  static Future<bool> get _isOnWifi async {
    final List<ConnectivityResult> status =
        await Connectivity().checkConnectivity();
    return status.contains(ConnectivityResult.wifi);
  }

  static Future<String> _parseCommentTextHtml(String text) async {
    return HtmlUnescape()
        .convert(text)
        .replaceAllMapped(
          RegExp(
            r'\<div class="reply"\>(.*?)\<\/div\>',
            dotAll: true,
          ),
          (Match match) => '',
        )
        .replaceAllMapped(
          RegExp(
            r'\<span class="(.*?)"\>(.*?)\<\/span\>',
            dotAll: true,
          ),
          (Match match) => '${match[2]}',
        )
        .replaceAllMapped(
          RegExp(
            r'\<p\>(.*?)\<\/p\>',
            dotAll: true,
          ),
          (Match match) => '\n\n${match[1]}',
        )
        .replaceAllMapped(
          RegExp(r'\<a href=\"(.*?)\".*?\>.*?\<\/a\>'),
          (Match match) => match[1] ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\<i\>(.*?)\<\/i\>'),
          (Match match) => '*${match[1]}*',
        )
        .trim();
  }
}
