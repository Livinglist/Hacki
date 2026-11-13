import 'package:flutter_feather_icons/flutter_feather_icons.dart';
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
  share('Share', icon: FeatherIcons.share),
  viewInBrowser('View in Browser', icon: Icons.open_in_browser),
  reply('Reply', icon: Icons.message),
  viewInSeparateThread('View In Separate Thread', icon: Icons.list);

  const SlideAction(this.description, {required this.icon});

  /// The order in which actions are offered to the user, following the
  /// "more" bottom sheet. Preferences store [index], so the declaration
  /// order above must stay append-only.
  static const List<SlideAction> displayOrder = <SlideAction>[
    viewProfile,
    searchOnHackerNews,
    searchInThread,
    reply,
    upvote,
    downvote,
    favorite,
    share,
    viewInSeparateThread,
    viewInBrowser,
    timeMachine,
    goToParent,
  ];

  final String description;
  final IconData icon;

  @override
  String toString() => description;
}
