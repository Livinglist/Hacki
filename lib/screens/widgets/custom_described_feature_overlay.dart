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
      featureId: feature.featureId,
      overflowMode: OverflowMode.extendBackground,
      targetColor: Theme.of(context).colorScheme.primary,
      tapTarget: tapTarget,
      title: Text(feature.title),
      description: Text(
        feature.description,
        style: const TextStyle(fontSize: TextDimens.pt16),
      ),
      barrierDismissible: false,
      contentLocation: contentLocation,
      onBackgroundTap: () {
        HapticFeedbackUtil.light();
        FeatureDiscovery.completeCurrentStep(context);
        onComplete?.call();
        return Future<bool>.value(true);
      },
      onComplete: () async {
        HapticFeedbackUtil.light();
        onComplete?.call();
        return true;
      },
      child: child,
    );
  }
}
