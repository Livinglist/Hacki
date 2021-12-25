class CacheService {
  static final _tappedStories = <int>{};

  bool isFirstTimeReading(int storyId) => !_tappedStories.contains(storyId);

  void store(int storyId) => _tappedStories.add(storyId);
}
