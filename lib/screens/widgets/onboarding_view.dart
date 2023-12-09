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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.transparent,
        surfaceTintColor: Palette.transparent,
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
              height: MediaQuery.of(context).size.height * 0.8,
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
            bottom: MediaQuery.of(context).viewPadding.bottom,
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
              child: Icon(
                Icons.arrow_drop_down_outlined,
                size: TextDimens.pt36,
                color: Theme.of(context).colorScheme.onPrimary,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          elevation: Dimens.pt8,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Image.asset(path),
          ),
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
