import 'dart:async';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/profile/models/page_type.dart';
import 'package:hacki/screens/profile/widgets/enter_offline_mode_list_tile.dart';
import 'package:hacki/screens/profile/widgets/offline_list_tile.dart';
import 'package:hacki/screens/profile/widgets/tab_bar_settings.dart';
import 'package:hacki/screens/profile/widgets/text_scale_factor_settings.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Settings extends StatefulWidget {
  const Settings({
    required this.authState,
    required this.magicWord,
    required this.pageType,
    super.key,
  });

  final AuthState authState;
  final String magicWord;
  final PageType? pageType;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with ItemActionMixin, Loggable {
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
                  const EnterOfflineModeListTile(),
                  const OfflineListTile(),
                  const SizedBox(
                    height: Dimens.pt8,
                  ),
                  Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            const SizedBox(
                              width: Dimens.pt16,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('Default fetch mode'),
                                DropdownMenu<FetchMode>(
                                  initialSelection: preferenceState.fetchMode,
                                  dropdownMenuEntries: FetchMode.values
                                      .map(
                                        (FetchMode val) =>
                                            DropdownMenuEntry<FetchMode>(
                                          value: val,
                                          label: val.description,
                                        ),
                                      )
                                      .toList(),
                                  onSelected: (FetchMode? fetchMode) {
                                    if (fetchMode != null) {
                                      HapticFeedbackUtil.selection();
                                      context.read<PreferenceCubit>().update(
                                            FetchModePreference(
                                              val: fetchMode.index,
                                            ),
                                          );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Default comments order'),
                          DropdownMenu<CommentsOrder>(
                            initialSelection: preferenceState.order,
                            dropdownMenuEntries: CommentsOrder.values
                                .map(
                                  (CommentsOrder val) =>
                                      DropdownMenuEntry<CommentsOrder>(
                                    value: val,
                                    label: val.description,
                                  ),
                                )
                                .toList(),
                            onSelected: (CommentsOrder? order) {
                              if (order != null) {
                                HapticFeedbackUtil.selection();
                                context.read<PreferenceCubit>().update(
                                      CommentsOrderPreference(
                                        val: order.index,
                                      ),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: Dimens.pt16,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: Dimens.pt12,
                  ),
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: Dimens.pt16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Data source',
                          ),
                          DropdownMenu<HackerNewsDataSource>(
                            initialSelection: preferenceState.dataSource,
                            dropdownMenuEntries: HackerNewsDataSource.values
                                .map(
                                  (HackerNewsDataSource val) =>
                                      DropdownMenuEntry<HackerNewsDataSource>(
                                    value: val,
                                    label: val.description,
                                  ),
                                )
                                .toList(),
                            onSelected: (HackerNewsDataSource? source) {
                              if (source != null) {
                                HapticFeedbackUtil.selection();
                                context.read<PreferenceCubit>().update(
                                      HackerNewsDataSourcePreference(
                                        val: source.index,
                                      ),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: Dimens.pt12,
                  ),
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: Dimens.pt16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Date time display of comments',
                          ),
                          DropdownMenu<DateDisplayFormat>(
                            initialSelection: preferenceState.displayDateFormat,
                            dropdownMenuEntries: DateDisplayFormat.values
                                .map(
                                  (DateDisplayFormat val) =>
                                      DropdownMenuEntry<DateDisplayFormat>(
                                    value: val,
                                    label: val.description,
                                  ),
                                )
                                .toList(),
                            onSelected: (DateDisplayFormat? order) {
                              if (order != null) {
                                HapticFeedbackUtil.selection();
                                context.read<PreferenceCubit>().update(
                                      DateFormatPreference(
                                        val: order.index,
                                      ),
                                    );
                                DateDisplayFormat.clearCache();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: Dimens.pt12,
                  ),
                  const TabBarSettings(),
                  const TextScaleFactorSettings(),
                  const Divider(),
                  StoryTile(
                    showWebPreview: preferenceState.isComplexStoryTileEnabled,
                    showMetadata: preferenceState.isMetadataEnabled,
                    showUrl: preferenceState.isUrlEnabled,
                    showFavicon: preferenceState.isFaviconEnabled,
                    story: Story.placeholder(),
                    onTap: () => LinkUtil.launch(
                      Constants.guidelineLink,
                      context,
                    ),
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
                        HapticFeedbackUtil.light();

                        context
                            .read<PreferenceCubit>()
                            .update(preference.copyWith(val: val));

                        if (preference is MarkReadStoriesModePreference &&
                            val == false) {
                          context
                              .read<StoriesBloc>()
                              .add(ClearAllReadStories());
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    if (preference
                        is MarkReadStoriesModePreference) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimens.pt16,
                        ),
                        child: DropdownMenu<StoryMarkingMode>(
                          enabled: preferenceState.isMarkReadStoriesEnabled,
                          label: Text(StoryMarkingModePreference().title),
                          initialSelection: preferenceState.storyMarkingMode,
                          onSelected: (StoryMarkingMode? storyMarkingMode) {
                            if (storyMarkingMode != null) {
                              HapticFeedbackUtil.selection();
                              context.read<PreferenceCubit>().update(
                                    StoryMarkingModePreference(
                                      val: storyMarkingMode.index,
                                    ),
                                  );
                            }
                          },
                          dropdownMenuEntries: StoryMarkingMode.values
                              .map(
                                (StoryMarkingMode val) =>
                                    DropdownMenuEntry<StoryMarkingMode>(
                                  value: val,
                                  label: val.label,
                                ),
                              )
                              .toList(),
                          inputDecorationTheme: const InputDecorationTheme(
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Palette.grey,
                              ),
                            ),
                          ),
                          expandedInsets: EdgeInsets.zero,
                        ),
                      ),
                      const Divider(),
                    ],
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
                  ListTile(
                    title: const Text(
                      'Accent Color',
                    ),
                    onTap: showColorPicker,
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
                      'Import Favorites',
                    ),
                    onTap: () =>
                        onImportFavoritesTapped(context.read<FavCubit>()),
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
                  if (preferenceState.isDevModeEnabled)
                    ListTile(
                      title: const Text(
                        'Logs',
                      ),
                      onTap: () {
                        context.go(Paths.log.landing);
                      },
                    ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('nothing interesting here.'),
                    onTap: showAboutHackiDialog,
                    onLongPress: () {
                      final DevMode updatedDevMode =
                          DevMode(val: !preferenceState.isDevModeEnabled);
                      context.read<PreferenceCubit>().update(updatedDevMode);
                      HapticFeedbackUtil.heavy();
                      if (updatedDevMode.val) {
                        showSnackBar(content: 'You are a dev now.');
                      } else {
                        showSnackBar(content: 'Dev mode disabled');
                      }
                    },
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
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
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
                          context
                              .read<PreferenceCubit>()
                              .update(FontPreference(val: val.index));
                        }
                      },
                      title: Text(
                        font.uiLabel,
                        style: TextStyle(fontFamily: font.name),
                      ),
                    ),
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
      case AdaptiveThemeMode.dark:
        AdaptiveTheme.of(context).setDark();
      case AdaptiveThemeMode.system:
      case null:
        AdaptiveTheme.of(context).setSystem();
    }

    final Brightness brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    ThemeUtil.updateStatusBarSetting(brightness, val);
  }

  void showColorPicker() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(Dimens.pt18),
          title: Text(AppColorPreference().title),
          content: MaterialColorPicker(
            colors: materialColors,
            selectedColor: context.read<PreferenceCubit>().state.appColor,
            onMainColorChange: (ColorSwatch<dynamic>? color) {
              CommentTile.levelToBorderColors.clear();
              context.read<PreferenceCubit>().update(
                    AppColorPreference(
                      val: materialColors.indexOf(color ?? Palette.deepOrange),
                    ),
                  );
              context.pop();
            },
            onBack: context.pop,
          ),
        );
      },
    );
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
              onPressed: () => context.pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
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
                    .whenComplete(
                      locator.get<SembastRepository>().deleteCachedComments,
                    )
                    .whenComplete(
                      locator.get<SembastRepository>().deleteCachedMetadata,
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
              context,
            ),
            child: const Row(
              children: <Widget>[
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
              context,
            ),
            child: const Row(
              children: <Widget>[
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
            child: const Row(
              children: <Widget>[
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
              context,
            ),
            child: const Row(
              children: <Widget>[
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
              context,
            ),
            child: const Row(
              children: <Widget>[
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
              context,
            ),
            child: const Row(
              children: <Widget>[
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
          actionsPadding: const EdgeInsets.all(
            Dimens.pt16,
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: onSendEmailTapped,
              child: const Row(
                children: <Widget>[
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
              child: const Row(
                children: <Widget>[
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
      logError(error, stackTrace: stackTrace);
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
              onPressed: () => context.pop(),
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
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                final String keyword = controller.text.trim();
                if (keyword.isEmpty) return;
                context.read<FilterCubit>().addKeyword(keyword.toLowerCase());
                context.pop();
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
    return showModalBottomSheet<ExportDestination>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...ExportDestination.values.map(
                (ExportDestination e) => ListTile(
                  leading: Icon(e.icon),
                  title: Text(e.label),
                  onTap: () => context.pop<ExportDestination>(e),
                ),
              ),
            ],
          ),
        );
      },
    ).then(
      (ExportDestination? destination) => exportFavorites(to: destination),
    );
  }

  Future<void> onImportFavoritesTapped(FavCubit favCubit) async {
    final String? res = await router.push(Paths.qrCode.scanner) as String?;
    final List<int>? ids =
        res?.split('\n').map(int.tryParse).whereType<int>().toList();
    if (ids == null) return;
    for (final int id in ids) {
      await favCubit.addFav(id);
    }
    showSnackBar(content: 'Favorites imported successfully.');
  }

  Future<void> exportFavorites({required ExportDestination? to}) async {
    final ExportDestination? destination = to;
    if (destination == null) return;

    final List<int> allFavorites = context.read<FavCubit>().state.favIds;
    if (allFavorites.isEmpty) {
      showSnackBar(content: "You don't have any favorite item.");
      return;
    }
    final String allFavoritesStr = allFavorites.join('\n');

    switch (destination) {
      case ExportDestination.qrCode:
        await router.push(
          Paths.qrCode.viewer,
          extra: allFavoritesStr,
        );
      case ExportDestination.clipBoard:
        try {
          await Clipboard.setData(ClipboardData(text: allFavoritesStr))
              .whenComplete(HapticFeedbackUtil.selection);
          showSnackBar(
            content: 'Ids of favorites have been copied to clipboard.',
          );
        } catch (error, stackTrace) {
          logError(error, stackTrace: stackTrace);
        }
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
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                try {
                  context.read<FavCubit>().removeAll();
                  showSnackBar(content: 'All favorites have been removed.');
                } catch (error, stackTrace) {
                  logError(error, stackTrace: stackTrace);
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

  @override
  String get logIdentifier => '[Settings]';
}
