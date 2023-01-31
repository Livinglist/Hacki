import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({
    super.key,
    required this.homeScreen,
  });

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: homeScreen),
        if (!context.read<ReminderCubit>().state.hasShown)
          const Positioned(
            left: Dimens.pt24,
            right: Dimens.pt24,
            bottom: Dimens.pt36,
            height: Dimens.pt40,
            child: CountdownReminder(),
          ),
      ],
    );
  }
}
