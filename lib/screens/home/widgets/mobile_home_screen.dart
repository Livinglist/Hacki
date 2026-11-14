import 'package:hacki/screens/home/widgets/home_reminder.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart' hide Badge;

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({required this.homeScreen, super.key});

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: homeScreen),
        const Positioned(
          left: Dimens.pt24,
          right: Dimens.pt24,
          bottom: Dimens.pt36,
          height: Dimens.pt40,
          child: HomeReminder(),
        ),
      ],
    );
  }
}
