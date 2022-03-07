import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    Key? key,
    this.showExitButton = false,
  }) : super(key: key);

  final bool showExitButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      buildWhen: (previous, current) =>
          previous.offlineReading != current.offlineReading,
      builder: (context, state) {
        if (state.offlineReading) {
          return MaterialBanner(
            content: Text(
              'You are currently in offline mode. '
              '${showExitButton ? 'Exit to fetch latest stories.' : ''}',
              textAlign: showExitButton ? TextAlign.left : TextAlign.center,
            ),
            backgroundColor: Colors.orangeAccent.withOpacity(0.3),
            actions: [
              if (showExitButton)
                TextButton(
                  onPressed: () {
                    context.read<StoriesBloc>().add(StoriesExitOffline());
                  },
                  child: const Text('Exit'),
                )
              else
                Container(),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
