import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class PinnedItemTile extends StatelessWidget {
  const PinnedItemTile({
    required this.item,
    required this.preferenceState,
    required this.onTap,
    super.key,
  });

  final Item item;
  final PreferenceState preferenceState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Item item = this.item;
    if (item is Story) {
      return StoryTile(
        story: item,
        onTap: onTap,
        shouldShowWebPreview: preferenceState.isRichStoryTileEnabled,
        shouldShowMetadata: preferenceState.isMetadataEnabled,
        shouldShowUrl: preferenceState.isUrlEnabled,
        shouldShowFavicon: preferenceState.isFaviconEnabled,
        shouldShowPreviewImage: preferenceState.isStoryTilePreviewImageEnabled,
        isImageLeftAligned: preferenceState.isPreviewImageLeftAligned,
        isExpandedTileEnabled: false,
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.pt12,
          vertical: Dimens.pt8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${item.timeAgo} by ${item.by}',
              style: TextStyle(color: Theme.of(context).metadataColor),
            ),
            Linkify(
              text: item.deleted ? 'deleted' : item.text,
              maxLines: 4,
              style: const TextStyle(fontSize: TextDimens.pt16),
              linkStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              onOpen: (LinkableElement link) =>
                  LinkUtils.launch(link.url, context),
            ),
          ],
        ),
      ),
    );
  }
}
