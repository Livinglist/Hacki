import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class PinIconButton extends StatelessWidget {
  const PinIconButton({
    super.key,
    required this.story,
  });

  final Story story;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinCubit, PinState>(
      builder: (BuildContext context, PinState pinState) {
        final bool pinned = pinState.pinnedStoriesIds.contains(story.id);
        return Transform.rotate(
          angle: pi / 4,
          child: Transform.translate(
            offset: const Offset(2, 0),
            child: IconButton(
              tooltip: 'Pin to home screen',
              icon: CustomDescribedFeatureOverlay(
                tapTarget: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Palette.white,
                ),
                featureId: Constants.featurePinToTop,
                title: const Text('Pin a Story'),
                description: const Text(
                  'Pin this story to the top of your '
                  'home screen so that you can come'
                  ' back later.',
                  style: TextStyle(fontSize: TextDimens.pt16),
                ),
                child: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: pinned
                      ? Palette.orange
                      : Theme.of(context).iconTheme.color,
                ),
              ),
              onPressed: () {
                HapticFeedbackUtil.light();
                if (pinned) {
                  context.read<PinCubit>().unpinStory(story);
                } else {
                  context.read<PinCubit>().pinStory(story);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
