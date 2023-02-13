import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/main.dart';
import 'package:hacki/repositories/repositories.dart';

abstract class FeatureDiscoveryUtil {
  static Future<void> discoverFeaturesOnFirstLaunch(
    BuildContext context, {
    required Iterable<String> featureIds,
  }) async {
    if (!isTesting) {
      await locator
          .get<PreferenceRepository>()
          .isFirstLaunch
          .then((bool isFirstLaunch) async {
        if (isFirstLaunch == false) return;

        if (context.mounted) {
          FeatureDiscovery.discoverFeatures(
            context,
            featureIds,
          );
        }
      });
    }
  }
}
