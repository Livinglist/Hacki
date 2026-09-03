import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class ReviewRequestBottomSheet extends StatefulWidget {
  const ReviewRequestBottomSheet({super.key});

  @override
  State<ReviewRequestBottomSheet> createState() =>
      _ReviewRequestBottomSheetState();
}

enum Stage { stars, reviewRequest, issueSubmission }

class _ReviewRequestBottomSheetState extends State<ReviewRequestBottomSheet> {
  final PageController pageController = PageController();
  Stage currentStage = .stars;
  int stars = 1;
  static const int maxStars = 5;

  @override
  Widget build(BuildContext context) {
    final Color highlightColor = Theme.of(context).colorScheme.primary;
    return Container(
      height: 360,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBoxes.pt24,
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Dimens.pt16,
                  horizontal: Dimens.pt12,
                ),
                child: Text(
                  'How would you rate Hacki so far?',
                  style: TextStyle(fontSize: TextDimens.pt20),
                  textAlign: .center,
                ),
              ),
              SizedBoxes.pt24,
              Row(
                mainAxisAlignment: .center,
                children: <Widget>[
                  for (final int i in List<int>.generate(
                    maxStars,
                    (int i) => i + 1,
                  )) ...<Widget>[
                    InkWell(
                      onTap: () {
                        HapticFeedbackUtils.selection();
                        setState(() {
                          stars = i;
                        });
                      },
                      customBorder: StarBorder(
                        side: BorderSide(
                          color: highlightColor,
                          width: Dimens.pt2,
                        ),
                      ),
                      child: Container(
                        height: Dimens.pt50,
                        width: Dimens.pt50,
                        decoration: ShapeDecoration(
                          color: i <= stars
                              ? highlightColor
                              : Palette.transparent,
                          shape: StarBorder(
                            side: i <= stars
                                ? .none
                                : BorderSide(
                                    color: highlightColor,
                                    width: Dimens.pt2,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBoxes.pt12,
                  ],
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedbackUtils.selection();
                  if (stars == maxStars) {
                    pageController.animateToPage(
                      Stage.reviewRequest.index,
                      duration: AppDurations.ms300,
                      curve: Curves.easeIn,
                    );
                  } else {
                    pageController.animateToPage(
                      Stage.issueSubmission.index,
                      duration: AppDurations.ms300,
                      curve: Curves.easeIn,
                    );
                  }
                },
                label: const Icon(Icons.check, size: TextDimens.pt64),
              ),
              SizedBoxes.pt36,
            ],
          ),
          Column(
            children: <Widget>[
              SizedBoxes.pt24,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Text(
                  'Would you like to leave a review?',
                  style: TextStyle(fontSize: TextDimens.pt20),
                  textAlign: .center,
                ),
              ),
              SizedBoxes.pt12,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Text(
                  '(๑•̀ㅂ•́)و✧',
                  style: TextStyle(fontSize: TextDimens.pt20),
                  textAlign: .center,
                ),
              ),
              SizedBoxes.pt12,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Text(
                  '''
Hacki is completely free and open source. Your feedback keeps me motivated to make it even better.''',
                  style: TextStyle(fontSize: TextDimens.pt16),
                  textAlign: .center,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: .center,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      context.pop();
                    },
                    label: const Icon(Icons.close, size: TextDimens.pt64),
                  ),
                  SizedBoxes.pt48,
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      LinkUtils.launch(
                        Platform.isIOS
                            ? Constants.appStoreLink
                            : Constants.googlePlayLink,
                        context,
                      );
                      context.pop();
                    },
                    label: const Icon(Icons.check, size: TextDimens.pt64),
                  ),
                ],
              ),
              SizedBoxes.pt48,
            ],
          ),
          Column(
            children: <Widget>[
              SizedBoxes.pt24,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Text(
                  'Would you like to share some feedback?',
                  style: TextStyle(fontSize: TextDimens.pt20),
                  textAlign: .center,
                ),
              ),
              SizedBoxes.pt12,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                child: Text(
                  '''
Hacki is completely free and open source. Your feedback keeps me motivated to make it even better. 
 
Tapping YES will take you to Hacki's GitHub page.''',
                  style: TextStyle(fontSize: TextDimens.pt16),
                  textAlign: .center,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: .center,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      context.pop();
                    },
                    label: const Icon(Icons.close, size: TextDimens.pt64),
                  ),
                  SizedBoxes.pt48,
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedbackUtils.selection();
                      LinkUtils.launch(Constants.githubLink, context);
                      context.pop();
                    },
                    label: const Icon(Icons.check, size: TextDimens.pt64),
                  ),
                ],
              ),
              SizedBoxes.pt48,
            ],
          ),
        ],
      ),
    );
  }
}
