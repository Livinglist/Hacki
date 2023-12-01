import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController pageController = PageController();
  final Throttle throttle = Throttle(delay: _throttleDelay);

  static const Duration _throttleDelay = AppDurations.ms100;
  static const double _screenshotHeight = 550;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).canvasColor,
        elevation: Dimens.zero,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Palette.white,
          ),
          onPressed: context.pop,
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.primary
          : null,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: Dimens.pt40,
            left: Dimens.zero,
            right: Dimens.zero,
            child: SizedBox(
              height: _screenshotHeight,
              child: PageView(
                controller: pageController,
                scrollDirection: Axis.vertical,
                children: const <Widget>[
                  _PageViewChild(
                    path: Constants.commentTileRightSlidePath,
                    description:
                        '''Swipe right to leave a comment, vote, and more.''',
                  ),
                  _PageViewChild(
                    path: Constants.commentTileLeftSlidePath,
                    description:
                        '''Swipe left to view all the ancestor comments.''',
                  ),
                  _PageViewChild(
                    path: Constants.commentTileTopTapPath,
                    description:
                        '''Tap on anywhere inside a comment tile to collapse.''',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: Dimens.pt40,
            left: Dimens.zero,
            right: Dimens.zero,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedbackUtil.light();
                if (pageController.page! >= 2) {
                  context.pop();
                } else {
                  throttle.run(() {
                    pageController.nextPage(
                      duration: AppDurations.ms600,
                      curve: SpringCurve.underDamped,
                    );
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.all(
                  Dimens.pt18,
                ),
              ),
              child: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                size: TextDimens.pt24,
                color: Palette.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageViewChild extends StatelessWidget {
  const _PageViewChild({
    required this.path,
    required this.description,
  });

  final String path;
  final String description;

  static const double _height = 400;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: _height,
          child: Image.asset(path),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt24,
            vertical: Dimens.pt24,
          ),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: TextDimens.pt16,
              color: Palette.white,
            ),
          ),
        ),
      ],
    );
  }
}
