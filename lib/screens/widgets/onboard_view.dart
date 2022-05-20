import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';

class OnboardView extends StatefulWidget {
  const OnboardView({Key? key}) : super(key: key);

  @override
  State<OnboardView> createState() => _OnboardViewState();
}

class _OnboardViewState extends State<OnboardView> {
  final PageController pageController = PageController();
  final Throttle throttle = Throttle(delay: _throttleDelay);

  static const Duration _throttleDelay = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.orange
            : Theme.of(context).canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.orange
          : null,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 550,
              child: PageView(
                controller: pageController,
                scrollDirection: Axis.vertical,
                children: const <Widget>[
                  _PageViewChild(
                    path: Constants.commentTileRightSlidePath,
                    description: 'Swipe right to leave a comment or vote.',
                  ),
                  _PageViewChild(
                    path: Constants.commentTileLeftSlidePath,
                    description: 'Swipe left to view all the parent comments.',
                  ),
                  _PageViewChild(
                    path: Constants.commentTileTopTapPath,
                    description: 'Tap on the top of comment tile to collapse.',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (pageController.page! >= 2) {
                  Navigator.pop(context);
                } else {
                  throttle.run(() {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: SpringCurve.underDamped,
                    );
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                primary: Colors.orange,
                padding: const EdgeInsets.all(18),
              ),
              child: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                size: 24,
                color: Colors.white,
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
    Key? key,
    required this.path,
    required this.description,
  }) : super(key: key);

  final String path;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 400,
          child: Image.asset(path),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
