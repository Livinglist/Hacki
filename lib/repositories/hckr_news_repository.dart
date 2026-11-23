import 'dart:convert';

import 'package:http/http.dart';

typedef _Entry = ({int id, int date, int index});

/// Stories ordered by when they first reached the Hacker News front page.
class HckrNewsRepository {
  HckrNewsRepository({Client? client}) : _client = client ?? Client();

  final Client _client;

  static final Uri _feedUrl = Uri.parse('https://hckrnews.com/data/latest.js');

  Future<List<int>> fetchStoryIds() async {
    final Response response = await _client
        .get(_feedUrl)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw ClientException(
        'Unable to fetch chronological stories (${response.statusCode}).',
        _feedUrl,
      );
    }

    // latest.js assigns a JSON array to `entries`; never evaluate JavaScript.
    String payload = response.body.trim();
    payload = payload.replaceFirst(RegExp(r'^var\s+entries\s*=\s*'), '');
    if (payload.endsWith(';')) {
      payload = payload.substring(0, payload.length - 1).trimRight();
    }

    final Object? decoded = jsonDecode(payload);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Expected a chronological stories array.');
    }

    final List<_Entry> entries = <_Entry>[];
    for (int index = 0; index < decoded.length; index++) {
      final dynamic entry = decoded[index];
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Expected a chronological story object.');
      }
      entries.add((
        id: _parseInt(entry['id'], 'id'),
        date: _parseInt(entry['date'], 'date'),
        index: index,
      ));
    }

    // `date` is the front-page arrival time; `time` is the submission time.
    // `homepage: false` means a story has since left the current front page.
    entries.sort((_Entry lhs, _Entry rhs) {
      final int byDate = rhs.date.compareTo(lhs.date);
      return byDate == 0 ? lhs.index.compareTo(rhs.index) : byDate;
    });

    return entries.map((_Entry entry) => entry.id).toSet().toList();
  }

  static int _parseInt(Object? value, String field) {
    final int? number = value is int
        ? value
        : value is String
        ? int.tryParse(value)
        : null;
    if (number == null || number <= 0) {
      throw FormatException('Invalid chronological story $field.');
    }
    return number;
  }
}
