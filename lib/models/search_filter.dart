part of 'search_params.dart';

abstract class SearchFilter {
  String get query;
}

abstract class NumericFilter extends SearchFilter {}

abstract class TagFilter extends SearchFilter {}

abstract class TypeTagFilter extends TagFilter {
  static List<TypeTagFilter> all = <TypeTagFilter>[
    const StoryFilter(),
    const PollFilter(),
    const CommentFilter(),
    const FrontPageFilter(),
    const AskHnFilter(),
    const ShowHnFilter(),
  ];
}

class DateTimeRangeFilter implements NumericFilter {
  const DateTimeRangeFilter({
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
  const PostedByFilter({required this.author});

  final String author;

  @override
  String get query {
    return 'author_$author';
  }
}

class FrontPageFilter implements TypeTagFilter {
  const FrontPageFilter();

  @override
  String get query {
    return 'front_page';
  }
}

class ShowHnFilter implements TypeTagFilter {
  const ShowHnFilter();

  @override
  String get query {
    return 'show_hn';
  }
}

class AskHnFilter implements TypeTagFilter {
  const AskHnFilter();

  @override
  String get query {
    return 'ask_hn';
  }
}

class PollFilter implements TypeTagFilter {
  const PollFilter();

  @override
  String get query {
    return 'poll';
  }
}

class StoryFilter implements TypeTagFilter {
  const StoryFilter();

  @override
  String get query {
    return 'story';
  }
}

class CommentFilter implements TypeTagFilter {
  const CommentFilter();

  @override
  String get query {
    return 'comment';
  }
}

class CombinedFilter implements TagFilter {
  const CombinedFilter({required this.filters});

  final List<TagFilter> filters;

  @override
  String get query {
    return '''(${filters.map((TagFilter e) => e.query).reduce((String value, String element) => '$value, $element')})''';
  }
}
