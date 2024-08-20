import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class EnterOfflineModeListTile extends StatelessWidget {
  const EnterOfflineModeListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.isOfflineReading != current.isOfflineReading,
      builder: (BuildContext context, StoriesState state) {
        return SwitchListTile(
          value: state.isOfflineReading,
          activeColor: Theme.of(context).colorScheme.primary,
          title: const Text('Offline Mode'),
          onChanged: (bool value) {
            HapticFeedbackUtil.light();
            context.read<StoriesBloc>().add(
                  value ? StoriesEnterOfflineMode() : StoriesExitOfflineMode(),
                );
          },
        );
      },
    );
  }
}
