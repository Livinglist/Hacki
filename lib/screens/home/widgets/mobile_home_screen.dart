import 'dart:io';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({
    required this.homeScreen,
    super.key,
  });

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: homeScreen),
        if (!context.read<ReminderCubit>().state.hasShown)
          Positioned(
            left: Dimens.pt24,
            right: Dimens.pt24,
            bottom: Platform.isIOS ? Dimens.pt36 : Dimens.pt64,
            height: Dimens.pt40,
            child: const CountdownReminder(),
          ),
      ],
    );
  }
}
