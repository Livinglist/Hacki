import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.showExitButton = false,
  });

  final bool showExitButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.isOfflineReading != current.isOfflineReading,
      builder: (BuildContext context, StoriesState state) {
        if (state.isOfflineReading) {
          return MaterialBanner(
            dividerColor: Palette.transparent,
            content: Text(
              'You are currently in offline mode. '
              '${showExitButton ? 'Exit to fetch latest stories.' : ''}',
              textAlign: showExitButton ? TextAlign.left : TextAlign.center,
            ),
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            actions: <Widget>[
              if (showExitButton)
                TextButton(
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Exit offline mode?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => context.pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => context.pop(true),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  color: Palette.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ).then((bool? value) {
                      if (context.mounted && (value ?? false)) {
                        context
                            .read<StoriesBloc>()
                            .add(StoriesExitOfflineMode());
                        context.read<AuthBloc>().add(AuthInitialize());
                        context.read<PinCubit>().init();
                        WebAnalyzer.cacheMap.clear();
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
        return const SizedBox.shrink();
      },
    );
  }
}
