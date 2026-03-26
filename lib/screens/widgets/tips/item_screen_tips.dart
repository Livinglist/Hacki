import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/styles/styles.dart';

class ItemScreenTips extends StatelessWidget {
  const ItemScreenTips({super.key});

  static const double _maxFeatureHintsImageWidth = 200;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: Dimens.zero,
      closedColor: Palette.transparent,
      openColor: Theme.of(context).colorScheme.surface,
      closedBuilder: (BuildContext context, void Function() action) {
        return IconButton(
          onPressed: action,
          icon: const Icon(
            Icons.tips_and_updates_outlined,
          ),
        );
      },
      openBuilder: (BuildContext context, void Function() action) {
        final double imageWidth = min(
          _maxFeatureHintsImageWidth,
          MediaQuery.of(context).size.width / 2 - Dimens.pt36,
        );
        context.read<TipsCubit>().completeTips(Tips.itemScreen);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tips'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.pt12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).padding.top,
                ),
                SizedBoxes.pt48,
                SizedBoxes.pt48,
                SizedBoxes.pt48,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Card(
                      elevation: Dimens.pt4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.pt6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimens.pt6),
                        child: Image.asset(
                          Constants.shareImageHintsFirst,
                          width: imageWidth,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    Card(
                      elevation: Dimens.pt4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.pt6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimens.pt6),
                        child: Image.asset(
                          Constants.shareImageHintsSecond,
                          width: imageWidth,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBoxes.pt24,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.pt12,
                  ),
                  child: Text(
                    '''You can select text in the comment before tapping on Share button and the text will be highlighted in resulted screenshot.''',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: TextDimens.pt16,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    TextButton(
                      onPressed: action,
                      child: const Text(
                        'Interesting',
                        style: TextStyle(
                          fontSize: TextDimens.pt16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: action,
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: TextDimens.pt16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBoxes.pt100,
              ],
            ),
          ),
        );
      },
    );
  }
}
