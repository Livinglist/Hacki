import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/utils.dart';

/// [SearchRepository] is for searching contents on Hacker News.
///
/// You can learn about the search API at https://hn.algolia.com/api.
class SearchRepository {
  SearchRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'http://hn.algolia.com/api/v1/';

  final Dio _dio;

  Stream<Item> search({
    required SearchParams params,
  }) async* {
    final String url = '$_baseUrl${params.filteredQuery}';
    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>(url);
    final Map<String, dynamic>? data = response.data;
    if (data == null) return;
    final Map<String, dynamic> json = data;
    final List<Map<String, dynamic>> hits =
        (json['hits'] as List<dynamic>).cast<Map<String, dynamic>>();

    if (hits.isEmpty) {
      return;
    }

    for (final Map<String, dynamic> hit in hits) {
      final String by = hit['author'] as String? ?? '';
      final String title = hit['title'] as String? ?? '';
      final int createdAt = hit['created_at_i'] as int? ?? 0;
      final int score = hit['points'] as int? ?? 0;
      final int descendants = hit['num_comments'] as int? ?? 0;

      final String url = hit['url'] as String? ?? '';
      final String type =
          title.toLowerCase().contains('poll:') ? 'poll' : 'story';
      final int id = int.parse(hit['objectID'] as String? ?? '0');

      if (title.isEmpty) {
        final String text = hit['comment_text'] as String? ?? '';
        final String parsedText = await compute<String, String>(
          HtmlUtil.parseHtml,
          text,
        );
        final int parentId = hit['parent_id'] as int? ?? 0;
        final Comment comment = Comment(
          id: id,
          score: score,
          time: createdAt,
          by: by,
          text: parsedText,
          kids: const <int>[],
          parent: parentId,
          dead: false,
          deleted: false,
          hidden: false,
          level: 0,
        );
        yield comment;
      } else {
        final String text = hit['story_text'] as String? ?? '';
        final String parsedText = await compute<String, String>(
          HtmlUtil.parseHtml,
          text,
        );
        final Story story = Story(
          descendants: descendants,
          id: id,
          score: score,
          time: createdAt,
          by: by,
          title: title,
          text: parsedText,
          url: url,
          type: type,
          // response doesn't contain kids and parts.
          kids: const <int>[],
          parts: const <int>[],
          hidden: false,
        );
        yield story;
      }
    }
    return;
  }
}
