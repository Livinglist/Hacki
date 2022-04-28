import 'package:dio/dio.dart';
import 'package:hacki/models/models.dart';

class SearchRepository {
  SearchRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'http://hn.algolia.com/api/v1/search?query=';

  final Dio _dio;

  Stream<Story> search(String query, {int page = 0}) async* {
    final String url = '$_baseUrl${Uri.encodeComponent(query)}&page=$page';
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

      // Getting rid of comments, only keeping stories for convenience.
      // Don't judge me.
      if (title.isEmpty) {
        continue;
      }

      final String url = hit['url'] as String? ?? '';
      final int id = int.parse(hit['objectID'] as String? ?? '0');
      final Story story = Story(
        descendants: 0,
        id: id,
        score: 0,
        time: createdAt,
        by: by,
        title: title,
        url: url,
        type: '',
        kids: const <int>[],
      );
      yield story;
    }
    return;
  }
}
