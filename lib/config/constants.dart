import 'package:hacki/extensions/extensions.dart';

abstract class Constants {
  static const String endUserAgreementLink =
      'https://github.com/Livinglist/Hacki/blob/master/assets/eula.md';
  static const String privacyPolicyLink =
      'https://github.com/Livinglist/Hacki/blob/master/assets/privacy_policy.md';
  static const String hackerNewsLogoLink =
      'https://pbs.twimg.com/profile_images/469397708986269696/iUrYEOpJ_400x400.png';
  static const String portfolioLink = 'https://github.com/Livinglist';
  static const String githubLink = 'https://github.com/Livinglist/Hacki';
  static const String appStoreLink =
      'https://apps.apple.com/us/app/hacki/id1602043763?action=write-review';
  static const String googlePlayLink =
      'https://play.google.com/store/apps/details?id=com.jiaqifeng.hacki&hl=en_US&gl=US';
  static const String sponsorLink = 'https://github.com/sponsors/Livinglist';
  static const String guidelineLink =
      'https://news.ycombinator.com/newsguidelines.html';
  static const String githubIssueLink =
      '$githubLink/issues/new?title=Found+a+bug+in+Hacki&body=Please+describe+the+problem.';
  static const String wikipediaLink = 'https://en.wikipedia.org/wiki/';
  static const String wiktionaryLink = 'https://en.wiktionary.org/wiki/';
  static const String hackerNewsItemLinkPrefix =
      'https://news.ycombinator.com/item?id=';
  static const String supportEmail = 'georgefung98@gmail.com';

  static const String _imagePath = 'assets/images';
  static const String hackerNewsLogoPath = '$_imagePath/hacker_news_logo.png';
  static const String hackiIconPath = '$_imagePath/hacki_icon.png';
  static const String commentTileLeftSlidePath =
      '$_imagePath/comment_tile_left_slide.png';
  static const String commentTileRightSlidePath =
      '$_imagePath/comment_tile_right_slide.png';
  static const String commentTileTopTapPath =
      '$_imagePath/comment_tile_top_tap.png';
  static const String logFilename = 'hacki_log.txt';
  static const String previousLogFileName = 'old_hacki_log.txt';

  static final String happyFace = <String>[
    '(๑•̀ㅂ•́)و✧',
    '( ͡• ͜ʖ ͡•)',
    '( ͡~ ͜ʖ ͡°)',
    '٩(˘◡˘)۶',
    '(─‿‿─)',
    '(¬‿¬)',
  ].pickRandomly()!;

  static final String sadFace = <String>[
    'ಥ_ಥ',
    '(╯°□°）╯︵ ┻━┻',
    r'¯\_(ツ)_/¯',
    '( ͡° ͜ʖ ͡°)',
    '(Θ︹Θ)',
    '( ˘︹˘ )',
    '(ㆆ_ㆆ)',
    'ʕ•́ᴥ•̀ʔっ',
    '(ㆆ_ㆆ)',
  ].pickRandomly()!;

  static final String magicWord = <String>[
    'to be over the rainbow!',
    'to infinity and beyond!',
    'to see the future.',
  ].pickRandomly()!;

  static final String errorMessage = 'Something went wrong...$sadFace';
  static final String loginErrorMessage =
      '''Failed to log in $sadFace, this could happen if your account requires a CAPTCHA, please try logging in inside a browser to see if this is the case, if so, you may try logging in here again later after CAPTCHA is no longer needed.''';
}

abstract class RegExpConstants {
  static const String linkSuffix = r'(\)|]|,|\*)(.)*$';
  static const String number = '[0-9]+';
}

abstract class AppDurations {
  static const Duration ms100 = Duration(milliseconds: 100);
  static const Duration ms200 = Duration(milliseconds: 200);
  static const Duration ms300 = Duration(milliseconds: 300);
  static const Duration ms400 = Duration(milliseconds: 400);
  static const Duration ms500 = Duration(milliseconds: 500);
  static const Duration ms600 = Duration(milliseconds: 600);
  static const Duration oneSecond = Duration(seconds: 1);
  static const Duration twoSeconds = Duration(seconds: 2);
  static const Duration tenSeconds = Duration(seconds: 10);
}
