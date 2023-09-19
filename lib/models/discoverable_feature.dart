enum DiscoverableFeature {
  addStoryToFavList(
    featureId: 'add_story_to_fav_list',
    title: 'Fav a Story',
    description: '''Add it to your favorites''',
  ),
  openStoryInWebView(
    featureId: 'open_story_in_web_view',
    title: 'Open in Browser',
    description: '''You can tap here to open this story in browser.''',
  ),
  login(
    featureId: 'log_in',
    title: 'Log in for more',
    description:
        '''Log in using your Hacker News account to check out stories and comments you have posted in the past, and get in-app notification when there is new reply to your comments or stories.''',
  ),
  pinToTop(
    featureId: 'pin_to_top',
    title: 'Pin a Story',
    description:
        '''Pin this story to the top of your home screen so that you can come back later.''',
  ),
  jumpUpButton(
    featureId: 'jump_up_button_with_long_press',
    title: 'Shortcut',
    description:
        '''Tapping on this button will take you to the previous off-screen root level comment.\n\nLong press on it to jump to the very beginning of this thread.''',
  ),
  jumpDownButton(
    featureId: 'jump_down_button_with_long_press',
    title: 'Shortcut',
    description:
        '''Tapping on this button will take you to the next off-screen root level comment.\n\nLong press on it to jump to the end of this thread.''',
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
