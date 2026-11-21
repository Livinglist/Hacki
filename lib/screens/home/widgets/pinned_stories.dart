import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart' hide Badge;

class PinnedStories extends StatelessWidget {
  const PinnedStories({
    required this.preferenceState,
    required this.onItemTapped,
    super.key,
  });

  final PreferenceState preferenceState;
  final void Function(Item item) onItemTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinCubit, PinState>(
      builder: (BuildContext context, PinState state) {
        return Column(
          children: <Widget>[
            for (final Item item in state.pinnedItems)
              FadeIn(
                child: Slidable(
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: <Widget>[
                      CustomSlidableAction(
                        onPressed: (_) {
                          HapticFeedbackUtils.light();
                          context.read<PinCubit>().unpinItem(
                            item,
                            onDone: () => context.showSnackBar(
                              content: SnackBarMessages.storyUnpinned,
                            ),
                          );
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
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    child: PinnedItemTile(
                      key: ValueKey<String>('${item.id}-PinnedItemTile'),
                      item: item,
                      preferenceState: preferenceState,
                      onTap: () => onItemTapped(item),
                    ),
                  ),
                ),
              ),
            if (state.pinnedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.pt12,
                  vertical: Dimens.pt4,
                ),
                child: Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
          ],
        );
      },
    );
  }
}
