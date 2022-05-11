import 'dart:math';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';

class PinIconButton extends StatelessWidget {
  const PinIconButton({
    Key? key,
    required this.story,
    required this.onBackgroundTap,
    required this.onDismiss,
  }) : super(key: key);

  final Story story;
  final Future<bool> Function() onBackgroundTap;
  final Future<bool> Function() onDismiss;

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
              icon: DescribedFeatureOverlay(
                onBackgroundTap: onBackgroundTap,
                onDismiss: onDismiss,
                overflowMode: OverflowMode.extendBackground,
                targetColor: Theme.of(context).primaryColor,
                tapTarget: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.white,
                ),
                featureId: Constants.featurePinToTop,
                title: const Text('Pin a Story'),
                description: const Text(
                  'Pin this story to the top of your '
                  'home screen so that you can come'
                  ' back later.',
                  style: TextStyle(fontSize: 16),
                ),
                child: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: pinned
                      ? Colors.orange
                      : Theme.of(context).iconTheme.color,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
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
