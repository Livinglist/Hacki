import 'package:hacki/models/search/filters/search_filter.dart';

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

final class FrontPageFilter implements TypeTagFilter {
  const FrontPageFilter();

  @override
  String get query {
    return 'front_page';
  }
}

final class ShowHnFilter implements TypeTagFilter {
  const ShowHnFilter();

  @override
  String get query {
    return 'show_hn';
  }
}

final class AskHnFilter implements TypeTagFilter {
  const AskHnFilter();

  @override
  String get query {
    return 'ask_hn';
  }
}

final class PollFilter implements TypeTagFilter {
  const PollFilter();

  @override
  String get query {
    return 'poll';
  }
}

final class StoryFilter implements TypeTagFilter {
  const StoryFilter();

  @override
  String get query {
    return 'story';
  }
}

final class CommentFilter implements TypeTagFilter {
  const CommentFilter();

  @override
  String get query {
    return 'comment';
  }
}

final class CombinedFilter implements TagFilter {
  const CombinedFilter({required this.filters});

  final List<TagFilter> filters;

  @override
  String get query {
    return '''(${filters.map((TagFilter e) => e.query).reduce((String value, String element) => '$value, $element')})''';
  }
}
