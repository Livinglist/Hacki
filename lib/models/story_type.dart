enum StoryType {
  top('topstories', ''),
  best('beststories', 'best'),
  latest('newstories', 'newest'),
  ask('askstories', 'ask'),
  show('showstories', 'show');

  const StoryType(
    this.apiPathParam,
    this.webPathParam,
  );

  /// The path param used in the official Hacker News API.
  /// e.g. https://hacker-news.firebaseio.com/v0/{apiPathParam}.json
  final String apiPathParam;

  /// The path param used in the HN web.
  /// e.g. https://news.ycombinator.com/{webPathParam}
  final String webPathParam;

  String get label {
    switch (this) {
      case StoryType.top:
        return 'TOP';
      case StoryType.best:
        return 'BEST';
      case StoryType.latest:
        return 'NEW';
      case StoryType.ask:
        return 'ASK';
      case StoryType.show:
        return 'SHOW';
    }
  }

  static int convertToSettingsValue(List<StoryType> tabs) {
    return int.parse(
      tabs
          .map((StoryType e) => e.index.toString())
          .reduce((String value, String element) => '$value$element'),
    );
  }
}
