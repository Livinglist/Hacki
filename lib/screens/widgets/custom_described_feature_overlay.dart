import 'dart:async';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class CustomDescribedFeatureOverlay extends StatelessWidget {
  const CustomDescribedFeatureOverlay({
    required this.feature,
    required this.child,
    required this.tapTarget,
    super.key,
    this.contentLocation = ContentLocation.trivial,
    this.onComplete,
  });

  final DiscoverableFeature feature;
  final Widget tapTarget;
  final Widget child;
  final ContentLocation contentLocation;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return DescribedFeatureOverlay(
      enablePulsingAnimation: !MediaQuery.of(context).disableAnimations,
      featureId: feature.featureId,
      overflowMode: OverflowMode.extendBackground,
      targetColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      tapTarget: tapTarget,
      title: Text(
        feature.title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      description: Text(
        feature.description,
        style: TextStyle(
          fontSize: TextDimens.pt16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      contentLocation: contentLocation,
      onBackgroundTap: () {
        HapticFeedbackUtils.light();
        FeatureDiscovery.completeCurrentStep(context);
        onComplete?.call();
        return Future<bool>.value(true);
      },
      onDismiss: () async {
        HapticFeedbackUtils.light();
        unawaited(FeatureDiscovery.completeCurrentStep(context));
        onComplete?.call();
        return false;
      },
      onComplete: () async {
        HapticFeedbackUtils.light();
        onComplete?.call();
        return true;
      },
      child: child,
    );
  }
}
