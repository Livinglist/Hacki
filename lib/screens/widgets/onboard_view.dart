import 'package:flutter/material.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
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
      backgroundColor: Colors.deepOrange,
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 120,
            ),
            SizedBox(
              height: 600,
              child: PageView(
                controller: pageController,
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
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (pageController.page! >= 2) {
                  Navigator.pop(context);
                } else {
                  throttle.run(() {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: SpringCurve.underDamped,
                    );
                  });
                }
              },
              child: const Text('Next'),
            ),
            const SizedBox(
              height: 60,
            ),
          ],
        ),
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
    return FadeIn(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 400,
            child: Image.asset(path),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 60,
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
      ),
    );
  }
}
