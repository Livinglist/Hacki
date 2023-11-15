/// Used for determining when to mark a story as read.
enum StoryMarkingMode {
  // Mark a story as read after user scrolls past it.
  scrollPast('scrolling past'),
  // Mark a story as read after user taps on it.
  tap('tapping'),
  // Mark a story as read after user scrolls past or taps on it, whichever
  // happens the first.
  scrollPastOrTap('scrolling past or tapping'),
  swipeGestureOnly('swipe gesture only');

  const StoryMarkingMode(this.label);

  final String label;

  bool get shouldDetectScrollingPast =>
      this == StoryMarkingMode.scrollPast ||
      this == StoryMarkingMode.scrollPastOrTap;

  bool get shouldDetectTapping =>
      this == StoryMarkingMode.tap || this == StoryMarkingMode.scrollPastOrTap;
}
