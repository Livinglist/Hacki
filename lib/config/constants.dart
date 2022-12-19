abstract class Constants {
  static const String endUserAgreementLink =
      'https://www.termsfeed.com/live/c1417f5c-a48b-4bd7-93b2-9cd4577bfc45';
  static const String hackerNewsLogoLink =
      'https://pbs.twimg.com/profile_images/469397708986269696/iUrYEOpJ_400x400.png';
  static const String portfolioLink = 'https://livinglist.github.io';
  static const String githubLink = 'https://github.com/Livinglist/Hacki';
  static const String appStoreLink =
      'https://apps.apple.com/us/app/hacki/id1602043763?action=write-review';
  static const String googlePlayLink =
      'https://play.google.com/store/apps/details?id=com.jiaqifeng.hacki&hl=en_US&gl=US';
  static const String sponsorLink = 'https://github.com/sponsors/Livinglist';

  static const String _imagePath = 'assets/images';
  static const String hackerNewsLogoPath = '$_imagePath/hacker_news_logo.png';
  static const String hackiIconPath = '$_imagePath/hacki_icon.png';
  static const String commentTileLeftSlidePath =
      '$_imagePath/comment_tile_left_slide.png';
  static const String commentTileRightSlidePath =
      '$_imagePath/comment_tile_right_slide.png';
  static const String commentTileTopTapPath =
      '$_imagePath/comment_tile_top_tap.png';

  /// Feature ids for feature discovery.
  static const String featureAddStoryToFavList = 'add_story_to_fav_list';
  static const String featureOpenStoryInWebView = 'open_story_in_web_view';
  static const String featureLogIn = 'log_in';
  static const String featurePinToTop = 'pin_to_top';

  static const List<String> happyFaces = <String>[
    '(๑•̀ㅂ•́)و✧',
    '( ͡• ͜ʖ ͡•)',
    '( ͡~ ͜ʖ ͡°)',
    '٩(˘◡˘)۶',
    '(─‿‿─)',
    '(¬‿¬)',
  ];

  static const List<String> sadFaces = <String>[
    'ಥ_ಥ',
    '(╯°□°）╯︵ ┻━┻',
    r'¯\_(ツ)_/¯',
    '( ͡° ͜ʖ ͡°)',
    '(Θ︹Θ)',
    '( ˘︹˘ )',
    '(ㆆ_ㆆ)',
    'ʕ•́ᴥ•̀ʔっ',
    '(ㆆ_ㆆ)',
  ];
}

abstract class RegExpConstants {
  static const String linkSuffix = r'(\)|])(.)*$';
  static const String number = r'\d+$';
}
