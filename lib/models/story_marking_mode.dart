/// Used for determining when to mark a story as read.
enum StoryMarkingMode {
  // Mark a story as read after user scrolls past it.
  scrollingPast('scrolling past'),
  // Mark a story as read after user taps on it.
  tap('tapping');

  const StoryMarkingMode(this.label);

  final String label;
}
