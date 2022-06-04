part of 'search_filters.dart';

abstract class SearchFilter {
  String get query;
}

abstract class NumericFilter extends SearchFilter {}

abstract class TagFilter extends SearchFilter {}

class DateTimeRangeFilter implements NumericFilter {
  DateTimeRangeFilter({
    this.startTime,
    this.endTime,
  });

  final DateTime? startTime;
  final DateTime? endTime;

  @override
  String get query {
    final int? startTimestamp = startTime == null
        ? null
        : startTime!.toUtc().millisecondsSinceEpoch ~/ 1000;
    final int? endTimestamp = endTime == null
        ? null
        : endTime!.toUtc().millisecondsSinceEpoch ~/ 1000;
    final String query =
        '''${startTimestamp == null ? '' : 'created_at_i>$startTimestamp'},${endTimestamp == null ? '' : 'created_at_i<$endTimestamp'}''';

    if (query.endsWith(',')) {
      return query.replaceFirst(',', '');
    }

    return query;
  }
}

class PostedByFilter implements TagFilter {
  PostedByFilter({required this.author});

  final String author;

  @override
  String get query {
    return 'author_$author';
  }
}

class FrontPageFilter implements TagFilter {
  FrontPageFilter();

  @override
  String get query {
    return 'front_page';
  }
}

class ShowHnFilter implements TagFilter {
  ShowHnFilter();

  @override
  String get query {
    return 'show_hn';
  }
}

class AskHnFilter implements TagFilter {
  AskHnFilter();

  @override
  String get query {
    return 'ask_hn';
  }
}

class PollFilter implements TagFilter {
  PollFilter();

  @override
  String get query {
    return 'poll';
  }
}

class StoryFilter implements TagFilter {
  StoryFilter();

  @override
  String get query {
    return 'story';
  }
}

class CombinedFilter implements TagFilter {
  CombinedFilter({required this.filters});

  final List<TagFilter> filters;

  @override
  String get query {
    return '''(${filters.map((TagFilter e) => e.query).reduce((String value, String element) => '$value, $element')})''';
  }
}
