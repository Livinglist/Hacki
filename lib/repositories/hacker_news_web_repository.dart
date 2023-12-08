import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart';

/// For fetching anything that cannot be fetched through Hacker News API.
class HackerNewsWebRepository {
  HackerNewsWebRepository();

  static const String _favoritesBaseUrl =
      'https://news.ycombinator.com/favorites?id=';
  static const String _aThingSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing';

  Future<Iterable<int>> fetchFavorites({required String of}) async {
    final String username = of;
    final List<int> allIds = <int>[];
    int page = 1;

    Future<Iterable<int>> fetchIds(int page, {bool isComment = false}) async {
      final Uri url = Uri.parse(
        '''$_favoritesBaseUrl$username${isComment ? '&comments=t' : ''}&p=$page''',
      );
      final Response response = await get(url);

      if (response.body.contains('Sorry')) {
        throw RateLimitedException();
      }

      /// Due to rate limiting, we have a short break here.
      await Future<void>.delayed(AppDurations.oneSecond);

      final Document document = parse(response.body);
      final List<Element> elements = document.querySelectorAll(_aThingSelector);
      final Iterable<int> parsedIds = elements
          .map(
            (Element e) => int.tryParse(e.id),
          )
          .whereNotNull();
      return parsedIds;
    }

    Iterable<int> ids;
    while (true) {
      ids = await fetchIds(page);
      if (ids.isEmpty) {
        break;
      }
      allIds.addAll(ids);
      page++;
    }

    page = 1;
    while (true) {
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

  Stream<Comment> fetchCommentsStream(int itemId) async* {
    Uri url = Uri.parse('$_itemBaseUrl$itemId');
    Response response = await get(url);
    Document document = parse(response.body);
    List<Element> elements = document.querySelectorAll(_athingComtrSelector);
    int page = 1;
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

        yield cmt;
      }

      page++;
      url = Uri.parse('$_itemBaseUrl$itemId&p=$page');
      response = await get(url);
      document = parse(response.body);
      elements = document.querySelectorAll(_athingComtrSelector);
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
