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
                    showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Exit offline mode?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).then((value) {
                      if (value ?? false) {
                        context.read<StoriesBloc>().add(StoriesExitOffline());
                        context.read<AuthBloc>().add(AuthInitialize());
                      }
                    });
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
