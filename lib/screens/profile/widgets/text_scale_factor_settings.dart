import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';

class TextScaleFactorSettings extends StatelessWidget {
  const TextScaleFactorSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.textScaleFactor != current.textScaleFactor,
      builder: (BuildContext context, PreferenceState state) {
        final String label = state.textScaleFactor == 1
            ? '''system default'''
            : state.textScaleFactor.toString();
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(
                  width: Dimens.pt16,
                ),
                Text('Text scale factor: $label'),
                const Spacer(),
              ],
            ),
            Slider(
              value: state.textScaleFactor,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              label: label,
              onChanged: (double value) => context
                  .read<PreferenceCubit>()
                  .update(TextScaleFactorPreference(val: value)),
            ),
          ],
        );
      },
    );
  }
}
