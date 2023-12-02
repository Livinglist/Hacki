import 'package:collection/collection.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
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
    int page = 0;

    Future<Iterable<int>> fetchIds(int page) async {
      final Uri url = Uri.parse('$_favoritesBaseUrl$username&p=$page');
      final Response response = await get(url);
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

    return allIds;
  }
}
