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
    required this.showWebPreview,
    required this.story,
    required this.onTap,
    this.showMultimedia = true,
  }) : super(key: key);

  final bool showWebPreview;
  final bool showMultimedia;
  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (showWebPreview) {
      final height = (MediaQuery.of(context).size.height) * 0.15;

      if (story.url.isNotEmpty) {
        return TapDownWrapper(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: AbsorbPointer(
              child: LinkPreview(
                showMultimedia: showMultimedia,
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
                          if (showMultimedia)
                            Expanded(
                              flex: 2,
                              child: Padding(
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
                bodyMaxLines: 4,
                errorTitle: story.title,
                titleStyle: TextStyle(
                  color: Theme.of(context).textTheme.subtitle1!.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      } else {
        final text = parse(story.text).body?.text ?? '';

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
                  imageUri: Constants.hackerNewsLogoLink,
                  showMultiMedia: showMultimedia,
                  bodyMaxLines: 4,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).textTheme.subtitle1!.color,
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
            children: [
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      style: const TextStyle(fontSize: 15),
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
