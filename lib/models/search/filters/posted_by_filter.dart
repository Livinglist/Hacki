import 'package:hacki/models/search/filters/tag_filter.dart';

final class PostedByFilter implements TagFilter {
  const PostedByFilter({required this.author});

  final String author;

  @override
  String get query {
    return 'author_$author';
  }
}
