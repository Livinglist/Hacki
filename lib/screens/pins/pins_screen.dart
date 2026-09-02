import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';

class PinsScreen extends StatefulWidget {
  const PinsScreen({super.key});

  static const String routeName = 'pins';

  @override
  State<PinsScreen> createState() => _PinsScreenState();
}

class _PinsScreenState extends State<PinsScreen> {
  final RefreshController refreshController = RefreshController();

  @override
  Widget build(BuildContext context) {
    final List<Story> pinnedStories = context
        .watch<PinCubit>()
        .state
        .pinnedStories;
    final PreferenceState preferenceState = context
        .watch<PreferenceCubit>()
        .state;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        elevation: Dimens.zero,
        title: const Text('Pins'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: pinnedStories.isEmpty ? Palette.grey : null,
            ),
            onPressed: () async {
              if (pinnedStories.isEmpty) return;
              final bool? isConfirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Remove all pins?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );

              if (context.mounted && (isConfirmed ?? false)) {
                context.read<PinCubit>().removeAll();
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.share,
              color: pinnedStories.isEmpty ? Palette.grey : null,
            ),
            onPressed: () async {
              if (pinnedStories.isEmpty) return;

              final String urls = pinnedStories
                  .map(
                    (Story s) =>
                        '''${s.title}\n${Constants.hackerNewsItemLinkPrefix}${s.id}''',
                  )
                  .join('\n\n');
              final ShareParams params = ShareParams(
                text: urls,
                subject: 'Pinned Stories on Hacker News',
              );
              await SharePlus.instance.share(params);
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          for (final Story story in pinnedStories)
            FadeIn(
              child: Slidable(
                startActionPane: ActionPane(
                  motion: const BehindMotion(),
                  children: <Widget>[
                    CustomSlidableAction(
                      onPressed: (_) {
                        HapticFeedbackUtils.light();
                        context.read<PinCubit>().unpinStory(story);
                      },
                      backgroundColor: Palette.red,
                      foregroundColor: Palette.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (preferenceState.isRichStoryTileEnabled)
                            const Icon(Icons.close, size: Dimens.pt24),
                          Text(
                            'Unpin',
                            style: TextStyle(
                              fontFamily: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                child: StoryTile(
                  key: ValueKey<String>('${story.id}-PinnedStoryTile'),
                  story: story,
                  onTap: () => context.onStoryTapped(story),
                  shouldShowWebPreview: preferenceState.isRichStoryTileEnabled,
                  shouldShowMetadata: preferenceState.isMetadataEnabled,
                  shouldShowUrl: preferenceState.isUrlEnabled,
                  shouldShowFavicon: preferenceState.isFaviconEnabled,
                  shouldShowPreviewImage:
                      preferenceState.isStoryTilePreviewImageEnabled,
                  isImageLeftAligned: preferenceState.isPreviewImageLeftAligned,
                  isExpandedTileEnabled: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
