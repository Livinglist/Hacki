enum DiscoverableFeature {
  addStoryToFavList(
    featureId: 'add_story_to_fav_list',
    title: 'Fav a Story',
    description: '''Add it to your favorites.''',
  ),
  settingsShortcutOnItemScreen(
    featureId: 'settings_shortcut_on_item_screen',
    title: 'Go to Settings',
    description: '''Tap to adjust thread appearance in Settings.''',
  ),
  login(
    featureId: 'log_in',
    title: 'Log in for more',
    description:
        '''Log in with your Hacker News account to view your past stories and comments and receive in-app notifications when someone replies to them.''',
  ),
  pinToTop(
    featureId: 'pin_to_top',
    title: 'Pin a Story',
    description: '''Pin this story to the top of your home screen.''',
  ),
  jumpUpButton(
    featureId: 'jump_up_button_with_long_press',
    title: 'Shortcut',
    description: '''
Tap this button to go to the previous root-level comment.

Long press to jump to the beginning of the thread.

Drag to move the button around.''',
  ),
  jumpDownButton(
    featureId: 'jump_down_button_with_long_press',
    title: 'Shortcut',
    description: '''
Tap this button to go to the next root-level comment.

Long press to jump to the end of the thread.

Drag to move the button around.''',
  ),
  searchInThread(
    featureId: 'search_in_thread',
    title: 'Search in Thread',
    description: '''Search for comments in this thread.''',
  );

  const DiscoverableFeature({
    required this.featureId,
    required this.title,
    required this.description,
  });

  /// Feature ids for feature discovery.
  final String featureId;
  final String title;
  final String description;
}
