import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/link_preview/link_view.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:html/parser.dart';
import 'package:shimmer/shimmer.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    Key? key,
    this.hasRead = false,
    required this.showWebPreview,
    required this.story,
    required this.onTap,
    this.simpleTileFontSize = 16,
  }) : super(key: key);

  final bool showWebPreview;
  final bool hasRead;
  final Story story;
  final VoidCallback onTap;
  final double simpleTileFontSize;

  @override
  Widget build(BuildContext context) {
    if (showWebPreview) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool showSmallerPreviewPic =
          Platform.isIOS && screenWidth > 428.0 && screenWidth < 850;
      final double height = showSmallerPreviewPic
          ? 100.0
          : (MediaQuery.of(context).size.height * 0.14).clamp(118.0, 140.0);

      if (story.url.isNotEmpty) {
        return TapDownWrapper(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: AbsorbPointer(
              child: LinkPreview(
                link: story.url.isNotEmpty ? story.url : 's',
                placeholderWidget: FadeIn(
                  child: SizedBox(
                    height: height,
                    child: Shimmer.fromColors(
                      baseColor: Colors.orange,
                      highlightColor: Colors.orangeAccent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 5,
                              bottom: 5,
                              top: 5,
                            ),
                            child: Container(
                              height: height,
                              width: height,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: double.infinity,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 3),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 3),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 3),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                errorImage: Constants.hackerNewsLogoLink,
                backgroundColor: Colors.transparent,
                borderRadius: 0,
                removeElevation: true,
                bodyMaxLines: height == 100 ? 3 : 4,
                errorTitle: story.title,
                titleStyle: TextStyle(
                  color: hasRead
                      ? Colors.grey[500]
                      : Theme.of(context).textTheme.subtitle1!.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      } else {
        final String text = parse(story.text).body?.text ?? '';

        return TapDownWrapper(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: AbsorbPointer(
              child: SizedBox(
                height: height,
                child: LinkView(
                  title: story.title,
                  description: text,
                  onTap: (_) {},
                  url: '',
                  imagePath: Constants.hackerNewsLogoPath,
                  bodyMaxLines: height == 100 ? 3 : 4,
                  titleTextStyle: TextStyle(
                    color: hasRead
                        ? Colors.grey[500]
                        : Theme.of(context).textTheme.subtitle1!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      story.title,
                      style: TextStyle(
                        color: hasRead ? Colors.grey[500] : null,
                        fontSize: simpleTileFontSize,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      );
    }
  }
}
