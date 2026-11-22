import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class PinIconButton extends StatelessWidget {
  const PinIconButton({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinCubit, PinState>(
      builder: (BuildContext context, PinState pinState) {
        final bool pinned = pinState.pinnedItemsIds.contains(item.id);
        return Transform.rotate(
          angle: pi / 4,
          child: Transform.translate(
            offset: const Offset(2, 0),
            child: IconButton(
              tooltip: 'Pin to home screen',
              icon: CustomDescribedFeatureOverlay(
                tapTarget: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                feature: DiscoverableFeature.pinToTop,
                child: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: pinned
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () {
                HapticFeedbackUtils.light();
                if (pinned) {
                  context.read<PinCubit>().unpinItem(
                    item,
                    onDone: () => context.showPinSnackBar(isPinned: false),
                  );
                } else {
                  context.read<PinCubit>().pinItem(
                    item,
                    onDone: () => context.showPinSnackBar(isPinned: true),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
