import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

/// For fetching anything that cannot be fetched through Hacker News API.
class HackerNewsWebRepository {
  HackerNewsWebRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const Map<String, String> _headers = <String, String>{
    'authority': 'www.google.com',
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'max-age=0',
    'sec-ch-ua':
        '"Not/A)Brand";v="99", "Google Chrome";v="115", "Chromium";v="115"',
    'sec-ch-ua-arch': '"x86"',
    'sec-ch-ua-bitness': '"64"',
    'sec-ch-ua-full-version': '"115.0.5790.110"',
    'sec-ch-ua-full-version-list':
        '"Not/A)Brand";v="99.0.0.0", "Google Chrome";v="115.0.5790.110", "Chromium";v="115.0.5790.110"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-model': '""',
    'sec-ch-ua-platform': 'Windows',
    'sec-ch-ua-platform-version': '15.0.0',
    'sec-ch-ua-wow64': '?0',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
    'x-client-data': '#..',
  };

  static const String _favoritesBaseUrl =
      'https://news.ycombinator.com/favorites?id=';
  static const String _aThingSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing';

  Future<Iterable<int>> fetchFavorites({required String of}) async {
    final String username = of;
    final List<int> allIds = <int>[];
    int page = 1;
    const int maxPage = 2;

    Future<Iterable<int>> fetchIds(int page, {bool isComment = false}) async {
      try {
        final Uri url = Uri.parse(
          '''$_favoritesBaseUrl$username${isComment ? '&comments=t' : ''}&p=$page''',
        );
        final Response<String> response = await _dio.getUri<String>(url);

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
  static const String _athingComtrSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing.comtr';
  static const String _commentTextSelector =
      '''td > table > tbody > tr > td.default > div.comment''';
  static const String _commentHeadSelector =
      '''td > table > tbody > tr > td.default > div > span > a''';
  static const String _commentAgeSelector =
      '''td > table > tbody > tr > td.default > div > span > span.age''';
  static const String _commentIndentSelector =
      '''td > table > tbody > tr > td.ind''';

  Stream<Comment> fetchCommentsStream(Item item) async* {
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
        final Response<String> response = await _dio.getUri<String>(
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
