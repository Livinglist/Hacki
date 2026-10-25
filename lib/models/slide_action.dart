import 'package:material_ui/material_ui.dart' show IconData, Icons;

enum SlideAction {
  upvote('Upvote', icon: Icons.thumb_up),
  downvote('Downvote', icon: Icons.thumb_down),
  timeMachine('Time Machine', icon: Icons.av_timer),
  goToParent('Go To Parent', icon: Icons.arrow_upward),
  viewProfile('View Profile', icon: Icons.account_circle),
  searchOnHackerNews('Search on HN', icon: Icons.search),
  searchInThread('Search in Thread', icon: Icons.manage_search),
  favorite('Favorite', icon: Icons.favorite),
  share('Share', icon: Icons.share),
  viewInBrowser('View in Browser', icon: Icons.open_in_browser),
  reply('Reply', icon: Icons.message);

  const SlideAction(this.description, {required this.icon});

  final String description;
  final IconData icon;

  @override
  String toString() => description;
}
