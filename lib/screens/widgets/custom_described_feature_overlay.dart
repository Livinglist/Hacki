import 'dart:async';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:hacki/utils/utils.dart';

class CustomDescribedFeatureOverlay extends StatelessWidget {
  const CustomDescribedFeatureOverlay({
    super.key,
    required this.featureId,
    required this.child,
    required this.tapTarget,
    required this.title,
    required this.description,
    this.contentLocation = ContentLocation.trivial,
    this.onComplete,
  });

  final String featureId;
  final Widget tapTarget;
  final Widget title;
  final Widget description;
  final Widget child;
  final ContentLocation contentLocation;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return DescribedFeatureOverlay(
      featureId: featureId,
      overflowMode: OverflowMode.extendBackground,
      targetColor: Theme.of(context).primaryColor,
      tapTarget: tapTarget,
      title: title,
      description: description,
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
