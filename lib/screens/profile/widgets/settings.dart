import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/profile/models/page_type.dart';
import 'package:hacki/screens/profile/widgets/offline_list_tile.dart';
import 'package:hacki/screens/profile/widgets/tab_bar_settings.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Settings extends StatefulWidget {
  const Settings({
    super.key,
    required this.authState,
    required this.magicWord,
    required this.pageType,
  });

  final AuthState authState;
  final String magicWord;
  final PageType pageType;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (BuildContext context, PreferenceState preferenceState) {
        return Positioned.fill(
          top: Dimens.pt50,
          child: Visibility(
            visible: widget.pageType == PageType.settings,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      widget.authState.isLoggedIn ? 'Log Out' : 'Log In',
                    ),
                    subtitle: Text(
                      widget.authState.isLoggedIn
                          ? widget.authState.username
                          : widget.magicWord,
                    ),
                    onTap: () {
                      if (widget.authState.isLoggedIn) {
                        onLogoutTapped();
                      } else {
                        onLoginTapped();
                      }
                    },
                  ),
                  const OfflineListTile(),
                  const SizedBox(
                    height: Dimens.pt8,
                  ),
                  Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Row(
                          children: const <Widget>[
                            SizedBox(
                              width: Dimens.pt16,
                            ),
                            Text('Default fetch mode'),
                            Spacer(),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          children: const <Widget>[
                            Text('Default comments order'),
                            Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            const SizedBox(
                              width: Dimens.pt16,
                            ),
                            DropdownButton<FetchMode>(
                              value: preferenceState.fetchMode,
                              underline: const SizedBox.shrink(),
                              items: FetchMode.values
                                  .map(
                                    (FetchMode val) =>
                                        DropdownMenuItem<FetchMode>(
                                      value: val,
                                      child: Text(
                                        val.description,
                                        style: const TextStyle(
                                          fontSize: TextDimens.pt16,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (FetchMode? fetchMode) {
                                if (fetchMode != null) {
                                  HapticFeedback.selectionClick();
                                  context.read<PreferenceCubit>().update(
                                        FetchModePreference(),
                                        to: fetchMode.index,
                                      );
                                }
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            DropdownButton<CommentsOrder>(
                              value: preferenceState.order,
                              underline: const SizedBox.shrink(),
                              items: CommentsOrder.values
                                  .map(
                                    (CommentsOrder val) =>
                                        DropdownMenuItem<CommentsOrder>(
                                      value: val,
                                      child: Text(
                                        val.description,
                                        style: const TextStyle(
                                          fontSize: TextDimens.pt16,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (CommentsOrder? order) {
                                if (order != null) {
                                  HapticFeedback.selectionClick();
                                  context.read<PreferenceCubit>().update(
                                        CommentsOrderPreference(),
                                        to: order.index,
                                      );
                                }
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const TabBarSettings(),
                  const Divider(),
                  StoryTile(
                    showWebPreview: preferenceState.complexStoryTileEnabled,
                    showMetadata: preferenceState.metadataEnabled,
                    showUrl: preferenceState.urlEnabled,
                    story: Story.placeholder(),
                    onTap: () => LinkUtil.launch(Constants.guidelineLink),
                  ),
                  const Divider(),
                  for (final Preference<dynamic> preference in preferenceState
                      .preferences
                      .whereType<BooleanPreference>()
                      .where(
                        (Preference<dynamic> e) => e.isDisplayable,
                      )) ...<Widget>[
                    SwitchListTile(
                      title: Text(preference.title),
                      subtitle: preference.subtitle.isNotEmpty
                          ? Text(preference.subtitle)
                          : null,
                      value: preferenceState.isOn(
                        preference as BooleanPreference,
                      ),
                      onChanged: (bool val) {
                        HapticFeedback.lightImpact();

                        context
                            .read<PreferenceCubit>()
                            .update(preference, to: val);

                        if (preference is MarkReadStoriesModePreference &&
                            val == false) {
                          context
                              .read<StoriesBloc>()
                              .add(ClearAllReadStories());
                        }
                      },
                      activeColor: Palette.orange,
                    ),
                    if (preference is StoryUrlModePreference) const Divider(),
                  ],
                  ListTile(
                    title: const Text(
                      'Font',
                    ),
                    onTap: showFontSettingDialog,
                  ),
                  ListTile(
                    title: const Text(
                      'Theme',
                    ),
                    onTap: showThemeSettingDialog,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      'Filter Keywords',
                    ),
                    onTap: onFilterKeywordsTapped,
                  ),
                  ListTile(
                    title: const Text(
                      'Export Favorites',
                    ),
                    onTap: onExportFavoritesTapped,
                  ),
                  ListTile(
                    title: const Text(
                      'Clear Favorites',
                    ),
                    onTap: showClearFavoritesDialog,
                  ),
                  ListTile(
                    title: const Text(
                      'Clear Cache',
                    ),
                    onTap: showClearCacheDialog,
                  ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('nothing interesting here.'),
                    onTap: showAboutHackiDialog,
                  ),
                  const SizedBox(
                    height: Dimens.pt48,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void onLogoutTapped() {
    final AuthBloc authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            'Log out as ${authBloc.state.username}?',
            style: const TextStyle(
              fontSize: TextDimens.pt16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogout());
                context.read<HistoryCubit>().reset();
              },
              child: const Text(
                'Log out',
              ),
            ),
          ],
        );
      },
    );
  }

  void showFontSettingDialog() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return BlocBuilder<PreferenceCubit, PreferenceState>(
          buildWhen: (PreferenceState previous, PreferenceState current) =>
              previous.font != current.font,
          builder: (BuildContext context, PreferenceState state) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final Font font in Font.values)
                    RadioListTile<Font>(
                      value: font,
                      groupValue: state.font,
                      onChanged: (Font? val) {
                        if (val != null) {
                          context.read<PreferenceCubit>().update(
                                FontPreference(),
                                to: val.index,
                              );
                        }
                      },
                      title: Text(
                        font.label,
                        style: TextStyle(fontFamily: font.name),
                      ),
                    ),
                  Row(
                    children: const <Widget>[
                      Text(
                        '*Restart required',
                        style: TextStyle(
                          fontSize: TextDimens.pt12,
                          color: Palette.grey,
                        ),
                      ),
                      Spacer(),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showThemeSettingDialog() {
    showDialog<void>(
      context: context,
      builder: (_) {
        final AdaptiveThemeMode themeMode = AdaptiveTheme.of(context).mode;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.light,
                groupValue: themeMode,
                onChanged: updateThemeSetting,
                title: const Text('Light'),
              ),
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.dark,
                groupValue: themeMode,
                onChanged: updateThemeSetting,
                title: const Text('Dark'),
              ),
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.system,
                groupValue: themeMode,
                onChanged: updateThemeSetting,
                title: const Text('System'),
              ),
            ],
          ),
        );
      },
    );
  }

  void updateThemeSetting(AdaptiveThemeMode? val) {
    switch (val) {
      case AdaptiveThemeMode.light:
        AdaptiveTheme.of(context).setLight();
        break;
      case AdaptiveThemeMode.dark:
        AdaptiveTheme.of(context).setDark();
        break;
      case AdaptiveThemeMode.system:
      case null:
        AdaptiveTheme.of(context).setSystem();
        break;
    }

    final Brightness brightness = Theme.of(context).brightness;
    ThemeUtil.updateAndroidStatusBarSetting(brightness, val);
  }

  void showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Clear Cache?'),
          content: const Text(
            'Clear all cached images, stories and comments.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Palette.orange,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                locator
                    .get<SembastRepository>()
                    .deleteAllCachedComments()
                    .whenComplete(
                      locator.get<OfflineRepository>().deleteAll,
                    )
                    .whenComplete(
                      locator.get<PreferenceRepository>().clearAllReadStories,
                    )
                    .whenComplete(
                      DefaultCacheManager().emptyCache,
                    )
                    .whenComplete(() {
                  showSnackBar(content: 'Cache cleared!');
                });
              },
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> showAboutHackiDialog() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;

    if (mounted) {
      showAboutDialog(
        context: context,
        applicationName: 'Hacki',
        applicationVersion: 'v$version',
        applicationIcon: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(
              Dimens.pt12,
            ),
          ),
          child: Image.asset(
            Constants.hackiIconPath,
            height: Dimens.pt50,
            width: Dimens.pt50,
          ),
        ),
        children: <Widget>[
          ElevatedButton(
            onPressed: () => LinkUtil.launch(
              Constants.portfolioLink,
            ),
            child: Row(
              children: const <Widget>[
                Icon(
                  FontAwesomeIcons.addressCard,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Developer'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => LinkUtil.launch(
              Constants.privacyPolicyLink,
            ),
            child: Row(
              children: const <Widget>[
                Icon(
                  Icons.privacy_tip_outlined,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Privacy policy'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onReportIssueTapped,
            child: Row(
              children: const <Widget>[
                Icon(
                  Icons.bug_report_outlined,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Report issue'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => LinkUtil.launch(
              Constants.githubLink,
            ),
            child: Row(
              children: const <Widget>[
                Icon(
                  FontAwesomeIcons.github,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Source code'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => LinkUtil.launch(
              Platform.isIOS
                  ? Constants.appStoreLink
                  : Constants.googlePlayLink,
            ),
            child: Row(
              children: const <Widget>[
                Icon(
                  Icons.thumb_up,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Like this app?'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => LinkUtil.launch(
              Constants.sponsorLink,
            ),
            child: Row(
              children: const <Widget>[
                Icon(
                  FeatherIcons.coffee,
                ),
                SizedBox(
                  width: Dimens.pt12,
                ),
                Text('Buy me a coffee'),
              ],
            ),
          ),
        ],
      );
    }
  }

  Future<void> onReportIssueTapped() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: <Widget>[
            ElevatedButton(
              onPressed: onSendEmailTapped,
              child: Row(
                children: const <Widget>[
                  Icon(
                    Icons.email,
                  ),
                  SizedBox(
                    width: Dimens.pt12,
                  ),
                  Text('Email'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => onGithubTapped(context.rect),
              child: Row(
                children: const <Widget>[
                  Icon(
                    Icons.bug_report_outlined,
                  ),
                  SizedBox(
                    width: Dimens.pt12,
                  ),
                  Text('GitHub'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Send an email with log attached.
  Future<void> onSendEmailTapped() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String previousLogPath =
        '${tempDir.path}/${Constants.previousLogFileName}';

    await LogUtil.exportLog();

    final Email email = Email(
      body:
          '''Please describe how to reproduce the bug or what you have down before the bug occurred:''',
      subject: 'Found a bug in Hacki',
      recipients: <String>[Constants.supportEmail],
      attachmentPaths: <String>[previousLogPath],
    );

    await FlutterEmailSender.send(email);
  }

  /// Open an issue on GitHub.
  Future<void> onGithubTapped(Rect? rect) async {
    try {
      final File originalFile = await LogUtil.exportLog();
      final XFile file = XFile(originalFile.path);
      final ShareResult result = await Share.shareXFiles(
        <XFile>[file],
        subject: 'hacki_log',
        sharePositionOrigin: rect,
      );

      if (result.status == ShareResultStatus.success) {
        LinkUtil.launchInExternalBrowser(Constants.githubIssueLink);
      }
    } catch (error, stackTrace) {
      error.logError(stackTrace: stackTrace);
    }
  }

  void onFilterKeywordsTapped() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Filter Keywords',
            style: TextStyle(
              fontSize: TextDimens.pt16,
            ),
          ),
          content: BlocBuilder<FilterCubit, FilterState>(
            builder: (BuildContext context, FilterState state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (state.keywords.isEmpty)
                    const CenteredText(
                      text:
                          '''story or comment that contains keywords here will be hidden.''',
                    ),
                  Wrap(
                    spacing: Dimens.pt4,
                    children: <Widget>[
                      for (final String keyword in state.keywords)
                        ActionChip(
                          avatar: const Icon(
                            Icons.close,
                            size: TextDimens.pt14,
                          ),
                          label: Text(keyword),
                          onPressed: () => context
                              .read<FilterCubit>()
                              .removeKeyword(keyword),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: onAddKeywordTapped,
              child: const Text(
                'Add keyword',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Okay',
              ),
            ),
          ],
        );
      },
    );
  }

  void onAddKeywordTapped() {
    final TextEditingController controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: TextField(
            autofocus: true,
            controller: controller,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                final String keyword = controller.text.trim();
                if (keyword.isEmpty) return;
                context.read<FilterCubit>().addKeyword(keyword.toLowerCase());
                Navigator.pop(context);
              },
              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> onExportFavoritesTapped() async {
    final List<int> allFavorites = context.read<FavCubit>().state.favIds;

    if (allFavorites.isEmpty) {
      showSnackBar(content: "You don't have any favorite item.");
      return;
    }

    try {
      await FlutterClipboard.copy(
        allFavorites.join('\n'),
      ).whenComplete(HapticFeedback.selectionClick);
      showSnackBar(content: 'Ids of favorites have been copied to clipboard.');
    } catch (error, stackTrace) {
      error.logError(stackTrace: stackTrace);
    }
  }

  void showClearFavoritesDialog() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove all favorites?'),
          content: const Text(
            '''This will not effect favorites saved in your Hacker News account.''',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                try {
                  context.read<FavCubit>().removeAll();
                  showSnackBar(content: 'All favorites have been removed.');
                } catch (error, stackTrace) {
                  error.logError(stackTrace: stackTrace);
                }
              },
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Palette.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
