import 'dart:async';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/widgets/link_preview/image_wrapped_text.dart';
import 'package:hacki/screens/widgets/link_preview/link_view.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

import 'support/fake_video_platform.dart';
import 'support/golden_harness.dart';
import 'support/widget_fixtures.dart';

Widget _gallery(List<Widget> children) => Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children,
  ),
);

StoryTile _storyTile({
  bool hasRead = false,
  bool preview = false,
  bool image = false,
  bool expanded = false,
  bool left = true,
}) => StoryTile(
  story: const WidgetStory(),
  shouldShowWebPreview: preview,
  shouldShowPreviewImage: image,
  shouldShowMetadata: true,
  shouldShowFavicon: !preview,
  shouldShowUrl: true,
  isExpandedTileEnabled: expanded,
  isImageLeftAligned: left,
  isIndexedStoryTileEnabled: true,
  index: 0,
  hasRead: hasRead,
  onTap: () {},
);

void main() {
  testGoldens('widgets', <GoldenScenario>[
    GoldenScenario(
      'status_and_basic_controls',
      () => _gallery(<Widget>[
        const CenteredText.hidden(),
        const CenteredText.deleted(),
        const CenteredText.dead(),
        const CenteredText.blocked(),
        const CenteredText.empty(),
        Wrap(
          spacing: 8,
          children: <Widget>[
            CustomChip(
              selected: false,
              label: 'unselected',
              onSelected: (_) {},
            ),
            CustomChip(selected: true, label: 'selected', onSelected: (_) {}),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CustomCircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 20),
        CustomDropdownMenu<String>(
          menuChildren: const <String>[
            'Natural',
            'Newest first',
            'Oldest first',
          ],
          onSelected: (_) {},
          selected: 'Natural',
        ),
      ]),
      covers: <String>{
        'lib/screens/widgets/centered_text.dart#CenteredText',
        'lib/screens/widgets/custom_chip.dart#CustomChip',
        'lib/screens/widgets/custom_circular_progress_indicator.dart#CustomCircularProgressIndicator',
        'lib/screens/widgets/custom_dropdown_menu.dart#CustomDropdownMenu',
      },
    ),
    GoldenScenario(
      'dropdown_open',
      () => _gallery(<Widget>[
        CustomDropdownMenu<String>(
          menuChildren: const <String>[
            'Natural',
            'Newest first',
            'Oldest first',
          ],
          onSelected: (_) {},
          selected: 'Natural',
        ),
      ]),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.text('Natural').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      },
      covers: <String>{
        'lib/screens/widgets/custom_dropdown_menu.dart#CustomDropdownMenu',
      },
    ),
    GoldenScenario(
      'wrappers_and_bloc_builders',
      () =>
          BlocBuilder3<
            PreferenceCubit,
            PreferenceState,
            AuthBloc,
            AuthState,
            BlocklistCubit,
            BlocklistState
          >(
            builder:
                (
                  BuildContext context,
                  PreferenceState preference,
                  AuthState auth,
                  BlocklistState blocklist,
                ) => _gallery(<Widget>[
                  OptionalWrapper(
                    enabled: true,
                    wrapper: (Widget child) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: child,
                      ),
                    ),
                    child: DeviceGestureWrapper(
                      child: TapDownWrapper(
                        onTap: () {},
                        child: const Text('Tap to open this item'),
                      ),
                    ),
                  ),
                  OptionalWrapper(
                    enabled: false,
                    wrapper: (Widget child) => Card(child: child),
                    child: const Text('Optional plain content'),
                  ),
                ]),
          ),
      covers: <String>{
        'lib/screens/widgets/bloc_builder/bloc_builder_3.dart#BlocBuilder3',
        'lib/screens/widgets/optional_wrapper.dart#OptionalWrapper',
        'lib/screens/widgets/device_gesture_wrapper.dart#DeviceGestureWrapper',
        'lib/screens/widgets/tap_down_wrapper.dart#TapDownWrapper',
      },
    ),
    for (final bool selectable in <bool>[false, true])
      GoldenScenario(
        selectable ? 'rich_text_selectable' : 'rich_text',
        () => Builder(
          builder: (BuildContext context) => _gallery(<Widget>[
            ItemText(
              item: widgetComment(),
              textScaler: MediaQuery.textScalerOf(context),
              selectable: selectable,
            ),
            const SizedBox(height: 20),
            ItemText(
              item: BuildableComment.fromComment(
                widgetComment(),
                elements: <LinkifyElement>[
                  TextElement('Prebuilt text: '),
                  EmphasisElement('emphasis'),
                  TextElement(' '),
                  QuoteElement('quotation'),
                  TextElement('\n'),
                  CodeElement('final count = 42;'),
                  TextElement(' '),
                  HighlightElement('highlighted match'),
                ],
              ),
              textScaler: MediaQuery.textScalerOf(context),
              selectable: selectable,
            ),
          ]),
        ),
        covers: <String>{
          'lib/screens/widgets/item_text.dart#ItemText',
          if (selectable)
            'lib/screens/widgets/custom_linkify/custom_linkify.dart#SelectableLinkify'
          else
            'lib/screens/widgets/custom_linkify/custom_linkify.dart#Linkify',
        },
      ),
    GoldenScenario(
      'story_tiles_unread_and_read',
      () => _gallery(<Widget>[
        _storyTile(),
        const Divider(),
        _storyTile(hasRead: true),
      ]),
      covers: <String>{'lib/screens/widgets/story_tile.dart#StoryTile'},
    ),
    for (final bool expanded in <bool>[false, true])
      GoldenScenario(
        expanded ? 'expanded_story_preview' : 'story_preview',
        () => _gallery(<Widget>[_storyTile(preview: true, expanded: expanded)]),
        covers: <String>{
          'lib/screens/widgets/story_tile.dart#StoryTile',
          'lib/screens/widgets/story_tile.dart#_LinkPreviewPlaceholder',
          'lib/screens/widgets/link_preview/link_preview.dart#LinkPreview',
          if (!expanded)
            'lib/screens/widgets/link_preview/link_view.dart#LinkView',
        },
      ),
    GoldenScenario(
      'story_preview_loading',
      () => _gallery(<Widget>[
        StoryTile(
          story: const WidgetStory(url: 'https://example.com/loading'),
          shouldShowWebPreview: true,
          shouldShowPreviewImage: false,
          shouldShowMetadata: true,
          shouldShowFavicon: false,
          shouldShowUrl: true,
          isExpandedTileEnabled: false,
          isImageLeftAligned: true,
          onTap: () {},
        ),
      ]),
      setup: () async {
        // Keep metadata pending so the real animated skeleton stays visible.
        when(
          () => locator.get<SembastRepository>().getCachedMetadata(
            key: any(named: 'key'),
          ),
        ).thenAnswer((_) => Completer<WebInfo?>().future);
      },
      covers: <String>{
        'lib/screens/widgets/story_tile.dart#_LinkPreviewPlaceholder',
      },
    ),
    GoldenScenario(
      'link_preview_with_asset',
      () => _gallery(<Widget>[
        SizedBox(
          height: 140,
          child: LinkView(
            metadata: '256 points 42 comments',
            url: '',
            readableUrl: '',
            title: 'Ask HN: What are you building?',
            description:
                'A description that wraps across several lines, '
                'next to a bundled Hacker News image.',
            onTap: () {},
            shouldShowUrl: true,
            bodyMaxLines: 5,
            isImageLeftAligned: false,
            imagePath: Constants.hackerNewsLogoPath,
          ),
        ),
      ]),
      covers: <String>{
        'lib/screens/widgets/link_preview/link_view.dart#LinkView',
        'lib/screens/widgets/link_preview/link_view.dart#_HackerNewsImage',
      },
    ),
    for (final bool left in <bool>[false, true])
      GoldenScenario(
        left ? 'wrapped_image_left' : 'wrapped_image_right',
        () => _gallery(<Widget>[
          ImageWrapText(
            text:
                'A long preview flows beside the image and '
                'then continues across the full width. '
                'Larger fonts and compact screens change '
                'where the paragraph continues. '
                'This final sentence makes the full '
                'width continuation visible.',
            image: Image.asset(Constants.hackerNewsLogoPath),
            imageHeight: 100,
            imageWidth: 100,
            onTap: () {},
            url: '',
            hasRead: !left,
            isImageLeftAligned: left,
          ),
        ]),
        covers: <String>{
          'lib/screens/widgets/link_preview/image_wrapped_text.dart#ImageWrapText',
        },
      ),
    for (final String state in <String>[
      'normal',
      'collapsed',
      'new',
      'pending',
      'hidden',
      'deleted',
      'dead',
      'blocked',
    ])
      GoldenScenario(
        'comment_$state',
        () => widgetBlocked(
          state == 'blocked',
          CommentTile(
            comment: widgetComment(
              id: state == 'pending' ? -1 : 101,
              collapsed: state == 'collapsed',
              isNew: state == 'new',
              hidden: state == 'hidden',
              deleted: state == 'deleted',
              dead: state == 'dead',
            ),
            fetchMode: FetchMode.eager,
            isActionable: state == 'collapsed',
            isSelectable: state == 'normal',
            isCollapsable: false,
            isResponse: true,
            opUsername: 'alice',
            level: 1,
            shouldHighlightNewComments: true,
          ),
        ),
        covers: <String>{
          'lib/screens/widgets/comment_tile.dart#CommentTile',
          'lib/screens/widgets/bloc_builder/bloc_builder_2.dart#BlocBuilder2',
          'lib/screens/widgets/item_slidable.dart#ItemSlidable',
        },
      ),
    for (final bool leading in <bool>[true, false])
      GoldenScenario(
        leading ? 'slidable_leading' : 'slidable_trailing',
        () => Builder(
          builder: (BuildContext context) => ItemSlidable(
            item: widgetComment(),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            onLeadingActionTapped: () {},
            onSecondaryActionTapped: () {},
            onTrailingActionTapped: () {},
            onMoreTapped: (_) {},
            child: const ListTile(
              key: Key('slide-child'),
              title: Text('A comment with swipe actions'),
              subtitle: Text('alice'),
            ),
          ),
        ),
        exercise: (WidgetTester tester) async {
          final SlidableController controller = Slidable.of(
            tester.element(find.byKey(const Key('slide-child'))),
          )!;
          if (leading) {
            unawaited(controller.openStartActionPane());
          } else {
            unawaited(controller.openEndActionPane());
          }
          await tester.pump(const Duration(milliseconds: 400));
        },
        covers: <String>{'lib/screens/widgets/item_slidable.dart#ItemSlidable'},
      ),
    for (final bool exit in <bool>[false, true])
      GoldenScenario(
        exit ? 'offline_banner_with_exit' : 'offline_banner',
        () => widgetStoriesState(
          const StoriesState.init().copyWith(isOfflineReading: true),
          OfflineBanner(shouldShowExitButton: exit),
        ),
        covers: <String>{
          'lib/screens/widgets/offline_banner.dart#OfflineBanner',
        },
      ),
    GoldenScenario(
      'download_progress',
      () => widgetStoriesState(
        const StoriesState.init().copyWith(
          downloadStatus: StoriesDownloadStatus.downloading,
          storiesDownloaded: 12,
          storiesToBeDownloaded: 40,
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(height: 70, child: DownloadProgressReminder()),
        ),
      ),
      covers: <String>{
        'lib/screens/widgets/download_progress_reminder.dart#DownloadProgressReminder',
      },
    ),
    GoldenScenario(
      'resume_reading_countdown',
      () => widgetReminder(
        const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(height: 60, child: CountdownReminder()),
        ),
      ),
      exercise: (WidgetTester tester) async {
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 400));
      },
      covers: <String>{
        'lib/screens/widgets/countdown_reminder.dart#CountdownReminder',
      },
    ),
    GoldenScenario(
      'tabs_with_unread_badge',
      () => widgetTabs(const _Tabs()),
      covers: <String>{
        'lib/screens/widgets/custom_tab_bar.dart#CustomTabBar',
        'lib/screens/widgets/custom_described_feature_overlay.dart#CustomDescribedFeatureOverlay',
      },
    ),
    GoldenScenario(
      'floating_button',
      () => Stack(
        children: <Widget>[
          DraggableFloatingButton(
            onTap: () {},
            child: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
      covers: <String>{
        'lib/screens/widgets/draggable_floating_button.dart#DraggableFloatingButton',
      },
    ),
    GoldenScenario(
      'indent_lines_and_painters',
      () => _gallery(<Widget>[
        const SizedBox(
          height: 100,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 100,
                child: AnimatedIndentLine(
                  color: Colors.orange,
                  width: 4,
                  isShining: false,
                ),
              ),
              SizedBox(
                width: 20,
                height: 100,
                child: AnimatedIndentLine(
                  color: Colors.blue,
                  width: 4,
                  isShining: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
          child: CustomPaint(painter: DashedLinePainter(color: Colors.orange)),
        ),
        SizedBox(
          height: 100,
          child: CustomPaint(painter: SpindlePainter(color: Colors.blue)),
        ),
        SizedBox(
          height: 50,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: ColoredBox(color: Colors.orange)),
              ShineOverlay(
                rect: const Rect.fromLTWH(0, 0, 280, 50),
                onDone: () {},
              ),
            ],
          ),
        ),
      ]),
      covers: <String>{
        'lib/screens/widgets/animated_indent_line.dart#AnimatedIndentLine',
        'lib/screens/widgets/shine_overlay.dart#ShineOverlay',
      },
    ),
    for (final int page in <int>[0, 1, 2])
      GoldenScenario(
        'onboarding_page_$page',
        () => const OnboardingView(),
        exercise: (WidgetTester tester) async {
          if (page > 0) {
            tester
                .widget<PageView>(find.byType(PageView))
                .controller!
                .jumpToPage(page);
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.pump();
        },
        covers: <String>{
          'lib/screens/widgets/onboarding_view.dart#OnboardingView',
          'lib/screens/widgets/onboarding_view.dart#_PageViewChild',
        },
      ),
    GoldenScenario(
      'share_tips',
      () => const ShareScreenTips(),
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.tips_and_updates_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
      },
      covers: <String>{
        'lib/screens/widgets/tips/share_screen_tips.dart#ShareScreenTips',
      },
    ),
    GoldenScenario(
      'item_tips',
      () => const ItemScreenTips(),
      setup: installGoldenVideoPlatform,
      exercise: (WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.tips_and_updates_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        for (final VideoPlayer player in tester.widgetList<VideoPlayer>(
          find.byType(VideoPlayer),
        )) {
          await player.controller.pause();
        }
        await tester.pump();
      },
      covers: <String>{
        'lib/screens/widgets/tips/item_screen_tips.dart#ItemScreenTips',
      },
    ),
  ]);
}

class _Tabs extends StatefulWidget {
  const _Tabs();
  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(
    length: StoryType.values.length + 1,
    vsync: this,
  );
  @override
  Widget build(BuildContext context) => CustomTabBar(tabController: controller);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
