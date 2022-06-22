import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart' show ReminderCubit, ReminderState;
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/story.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';

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
  static const Duration visibilityCountdownDuration = Duration(seconds: 3);

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
                color: Colors.deepOrange,
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: InkWell(
                  onTap: () {
                    if (state.storyId != null) {
                      locator
                          .get<StoriesRepository>()
                          .fetchStoryBy(state.storyId!)
                          .then((Story? story) {
                        if (story == null) {
                          showSnackBar(content: 'Something went wrong...');
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          top: 10,
                          right: 10,
                        ),
                        child: Row(
                          children: const <Widget>[
                            Text(
                              'Pick up where you left off',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.white,
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
