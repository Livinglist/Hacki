import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/hacker_news_repository.dart';
import 'package:hacki/utils/utils.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

/// For fetching anything that cannot be fetched through Hacker News API.
class HackerNewsWebRepository with Loggable {
  HackerNewsWebRepository({
    RemoteConfigCubit? remoteConfigCubit,
    HackerNewsRepository? hackerNewsRepository,
    Dio? dioWithCache,
    Dio? dio,
  })  : _dio = dio ?? Dio()
          ..interceptors.addAll(
            <Interceptor>[
              if (kDebugMode) LoggerInterceptor(),
            ],
          ),
        _dioWithCache = dioWithCache ?? Dio()
          ..interceptors.addAll(
            <Interceptor>[
              if (kDebugMode) LoggerInterceptor(),
              CacheInterceptor(),
            ],
          ),
        _remoteConfigCubit =
            remoteConfigCubit ?? locator.get<RemoteConfigCubit>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>() {
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  /// The client for fetching comments. We should be careful
  /// while fetching comments because it will easily trigger
  /// 503 from the server.
  final Dio _dioWithCache;

  /// The client for fetching stories.
  final Dio _dio;

  final RemoteConfigCubit _remoteConfigCubit;
  final HackerNewsRepository _hackerNewsRepository;

  static const Map<String, String> _headers = <String, String>{
    'accept': '*/*',
    'user-agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  };

  static const String _storiesBaseUrl = 'https://news.ycombinator.com';

  String get _storySelector => _remoteConfigCubit.state.storySelector;

  String get _titlelineSelector => _remoteConfigCubit.state.titlelineSelector;

  String get _subtextSelector => _remoteConfigCubit.state.subtextSelector;

  String get _pointSelector => _remoteConfigCubit.state.pointSelector;

  String get _userSelector => _remoteConfigCubit.state.userSelector;

  String get _ageSelector => _remoteConfigCubit.state.ageSelector;

  String get _cmtCountSelector => _remoteConfigCubit.state.cmtCountSelector;

  String get _moreLinkSelector => _remoteConfigCubit.state.moreLinkSelector;

  static final Map<int, int> _next = <int, int>{};
  static const List<int> _rateLimitedStatusCode = <int>[
    HttpStatus.forbidden,
    HttpStatus.serviceUnavailable,
  ];

  Stream<Story> fetchStoriesStream(
    StoryType storyType, {
    required int page,
  }) async* {
    Future<Iterable<(Element, Element)>> fetchElements(
      int page,
    ) async {
      try {
        final String urlStr = switch (storyType) {
          StoryType.top => '$_storiesBaseUrl?p=$page',
          StoryType.best ||
          StoryType.ask ||
          StoryType.show =>
            '$_storiesBaseUrl/${storyType.webPathParam}?p=$page',
          StoryType.latest =>
            '$_storiesBaseUrl/${storyType.webPathParam}?next=${_next[page]}'
        };

        final Uri url = Uri.parse(urlStr);
        final Options option = Options(
          headers: _headers,
          persistentConnection: true,
        );

        /// Be more conservative while user is on wifi.
        final Response<String> response = await _dio.getUri<String>(
          url,
          options: option,
        );

        final String data = response.data ?? '';
        final Document document = parse(data);
        final List<Element> elements =
            document.querySelectorAll(_storySelector);
        final List<Element> subtextElements =
            document.querySelectorAll(_subtextSelector);

        if (storyType == StoryType.latest) {
          /// Get the next id for latest stories.
          final Element? moreLinkElement =
              document.querySelector(_moreLinkSelector);

          /// Example: "newest?next=41240344&n=31"
          final String? href = moreLinkElement?.attributes['href'];
          final String? nextIdStr =
              href?.split('&n').firstOrNull?.split('=').lastOrNull;
          final int? nextId = int.tryParse(nextIdStr ?? '');

          if (nextId != null) {
            _next[page + 1] = nextId;
          }
        }

        return List<(Element, Element)>.generate(
          min(elements.length, subtextElements.length),
          (int index) =>
              (elements.elementAt(index), subtextElements.elementAt(index)),
        );
      } on DioException catch (e) {
        logError('error fetching stories on page $page: $e');
        if (_rateLimitedStatusCode.contains(e.response?.statusCode)) {
          throw RateLimitedWithFallbackException(e.response?.statusCode);
        }
        throw GenericException();
      }
    }

    final Set<int> fetchedStoryIds = <int>{};
    final Iterable<(Element, Element)> elements = await fetchElements(page);

    while (elements.isNotEmpty) {
      for (final (Element, Element) element in elements) {
        final Element titleElement = element.$1;
        final Element subtextElement = element.$2;

        /// Get id.
        final String? idStr = titleElement.attributes['id'];
        final int? id = int.tryParse(idStr ?? '');

        /// Get user.
        final Element? userElement =
            subtextElement.querySelector(_userSelector);
        final String? user = userElement?.nodes.firstOrNull?.text;

        /// Get post date.
        final Element? postDateElement =
            subtextElement.querySelector(_ageSelector) ??
                subtextElement.querySelector('.age');

        final String? dateStr = postDateElement?.attributes['title'];
        final int? timestamp = dateStr == null
            ? null
            : DateTime.parse(dateStr)
                .copyWith(isUtc: true)
                .millisecondsSinceEpoch;

        /// Get descendants.
        final Element? cmtCountElement =
            subtextElement.querySelectorAll(_cmtCountSelector).lastOrNull;
        final String cmtCountStr = cmtCountElement?.nodes.firstOrNull?.text
                ?.split('\u{00A0}')
                .firstOrNull ??
            '';
        final int cmtCount = int.tryParse(cmtCountStr) ?? 0;

        /// Get title;
        final Element? titlelineElement =
            titleElement.querySelector(_titlelineSelector);
        final String title = titlelineElement?.nodes.firstOrNull?.text ?? '';
        final String url = titlelineElement?.attributes['href'] ?? '';

        /// Get points.
        final Element? ptElement = subtextElement.querySelector(_pointSelector);

        /// Example: "80 points"
        final String? pointsStr = ptElement?.nodes.firstOrNull?.text;
        final int? points =
            int.tryParse(pointsStr?.split(' ').firstOrNull ?? '');

        if (id == null) continue;

        Story story = Story(
          id: id,
          time: timestamp ?? 0,
          score: points ?? 0,
          by: user ?? '',
          text: '',
          kids: const <int>[],
          hidden: false,
          descendants: cmtCount,
          title: title,
          type: 'story',
          url: storyType == StoryType.ask ? '$_itemBaseUrl$id' : url,
          parts: const <int>[],
        );

        /// If it is a story about launching or from ask section, then
        /// we need to fetch it from API since the html doesn't contain
        /// too much info.
        if (timestamp == null ||
            url.isEmpty ||
            url.contains('item?id=') ||
            title.contains('Launch HN:') ||
            title.contains('Ask HN:')) {
          final Story? fallbackStory = await _hackerNewsRepository
              .fetchStory(id: id)
              .timeout(AppDurations.fiveSeconds);
          if (fallbackStory != null) {
            story = fallbackStory;
          }
        }

        /// Duplicate story means we are done fetching all the stories.
        if (fetchedStoryIds.contains(story.id)) return;

        fetchedStoryIds.add(story.id);
        yield story;
      }

      /// Due to rate limiting, we have a short break here.
      await Future<void>.delayed(AppDurations.twoSeconds);
      return;
    }
  }

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
        if (_rateLimitedStatusCode.contains(e.response?.statusCode)) {
          logError('error fetching favorites on page $page: $e');
          throw RateLimitedException(e.response?.statusCode);
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
        if (_rateLimitedStatusCode.contains(e.response?.statusCode)) {
          logError('error fetching comments on page $page: $e');
          throw RateLimitedWithFallbackException(e.response?.statusCode);
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

  @override
  String get logIdentifier => 'HackerNewsWebRepository';
}
