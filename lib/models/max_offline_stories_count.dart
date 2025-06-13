enum MaxOfflineStoriesCount {
  ten(20, '20'),
  fifty(50, '50'),
  hundred(100, '100'),
  twoHundred(200, '200'),
  all(null, 'All');

  const MaxOfflineStoriesCount(this.count, this.label);

  final int? count;
  final String label;
}
