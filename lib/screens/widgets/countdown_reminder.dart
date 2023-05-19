import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart' show ReminderCubit, ReminderState;
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/styles/styles.dart';

class CountdownReminder extends StatefulWidget {
  const CountdownReminder({super.key});

  @override
  State<CountdownReminder> createState() => _CountDownReminderState();
}

class _CountDownReminderState extends State<CountdownReminder>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> progressAnimation;
  late final Animation<double> opacityAnimation;
  final Tween<double> progress = Tween<double>(
    begin: 0,
    end: 1,
  );
  final Tween<double> opacity = Tween<double>(
    begin: 1,
    end: 0,
  );

  bool isVisible = false;

  static const Duration countdownDuration = Duration(seconds: 8);
  static const Duration visibilityCountdownDuration = Duration.zero;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: countdownDuration,
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isVisible = false;
          });

          context.read<ReminderCubit>().onDismiss();
        }
      });

    progressAnimation = progress.animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0,
          0.8,
        ),
      ),
    );
    opacityAnimation = opacity.animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.8,
          1,
          curve: Curves.ease,
        ),
      ),
    );

    super.initState();

    Future<void>.delayed(visibilityCountdownDuration, () {
      setState(() {
        isVisible = true;
      });
      animationController.forward();
    });
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (BuildContext context, ReminderState state) {
        return Visibility(
          visible: isVisible && state.storyId != null,
          child: AnimatedBuilder(
            animation: animationController,
            child: FadeIn(
              child: Material(
                color: Palette.deepOrange,
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.all(
                  Radius.circular(
                    Dimens.pt4,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (state.storyId != null) {
                      locator
                          .get<StoriesRepository>()
                          .fetchStory(id: state.storyId!)
                          .then((Story? story) {
                        if (story == null) {
                          showErrorSnackBar();
                          return;
                        }
                        final ItemScreenArgs args = ItemScreenArgs(item: story);
                        goToItemScreen(args: args);

                        context.read<ReminderCubit>().removeLastReadStoryId();
                      });
                    }

                    context.read<ReminderCubit>().onDismiss();
                  },
                  child: Column(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(
                          left: Dimens.pt12,
                          top: Dimens.pt10,
                          right: Dimens.pt10,
                        ),
                        child: Row(
                          children: <Widget>[
                            Text(
                              'Pick up where you left off',
                              style: TextStyle(
                                color: Palette.white,
                                fontSize: TextDimens.pt12,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: TextDimens.pt12,
                              color: Palette.white,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: animationController,
                        builder: (BuildContext context, Widget? child) {
                          return LinearProgressIndicator(
                            value: progressAnimation.value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: opacityAnimation.value,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
