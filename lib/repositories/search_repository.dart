import 'package:dio/dio.dart';
import 'package:hacki/models/models.dart';

class SearchRepository {
  SearchRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const String baseUrl = 'http://hn.algolia.com/api/v1/search?query=';

  final Dio _dio;

  Stream<Story> search(String query, {int page = 0}) async* {
    final response =
        await _dio.get<Map<String, dynamic>>('$baseUrl$query&page=$page');
    final data = response.data;
    if (data == null) return;
    final json = data;
    final hits = (json['hits'] as List).cast<Map<String, dynamic>>();

    if (hits.isEmpty) {
      return;
    }

    for (final hit in hits) {
      final by = hit['author'] as String? ?? '';
      final title = hit['title'] as String? ?? '';
      final createdAt = hit['created_at_i'] as int? ?? 0;

      // Getting rid of comments, only keeping stories for convenience.
      // Don't judge me.
      if (title.isEmpty) {
        continue;
      }

      final url = hit['url'] as String? ?? '';
      final id = int.parse(hit['objectID'] as String? ?? '0');
      final story = Story(
        descendants: 0,
        id: id,
        score: 0,
        time: createdAt,
        by: by,
        title: title,
        url: url,
        type: '',
        kids: [],
      );
      yield story;
    }
    return;
  }
}
