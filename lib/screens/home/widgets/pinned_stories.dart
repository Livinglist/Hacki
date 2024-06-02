import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class PinnedStories extends StatelessWidget {
  const PinnedStories({
    required this.preferenceState,
    required this.onStoryTapped,
    super.key,
  });

  final PreferenceState preferenceState;
  final void Function(Story story) onStoryTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinCubit, PinState>(
      builder: (BuildContext context, PinState state) {
        return Column(
          children: <Widget>[
            for (final Story story in state.pinnedStories)
              FadeIn(
                child: Slidable(
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: <Widget>[
                      SlidableAction(
                        onPressed: (_) {
                          HapticFeedbackUtil.light();
                          context.read<PinCubit>().unpinStory(story);
                        },
                        backgroundColor: Palette.red,
                        foregroundColor: Palette.white,
                        icon: preferenceState.complexStoryTileEnabled
                            ? Icons.close
                            : null,
                        label: 'Unpin',
                      ),
                    ],
                  ),
                  child: ColoredBox(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: StoryTile(
                      key: ValueKey<String>('${story.id}-PinnedStoryTile'),
                      story: story,
                      onTap: () => onStoryTapped(story),
                      showWebPreview: preferenceState.complexStoryTileEnabled,
                      showMetadata: preferenceState.metadataEnabled,
                      showUrl: preferenceState.urlEnabled,
                      showFavicon: preferenceState.isFavIconEnabled,
                    ),
                  ),
                ),
              ),
            if (state.pinnedStories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Divider(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
              ),
          ],
        );
      },
    );
  }
}
