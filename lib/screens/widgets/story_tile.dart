import 'package:any_link_preview/any_link_preview.dart';
import 'package:any_link_preview/ui/link_view_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';
import 'package:html/parser.dart';
import 'package:shimmer/shimmer.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    Key? key,
    required this.showWebPreview,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  final bool showWebPreview;
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
              vertical: 8,
            ),
            child: AbsorbPointer(
              child: AnyLinkPreview(
                link: story.url.isNotEmpty ? story.url : 's',
                placeholderWidget: SizedBox(
                  width: 200,
                  height: height,
                  child: Shimmer.fromColors(
                    baseColor: Colors.orange,
                    highlightColor: Colors.orangeAccent,
                    child: ListView.builder(
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  height: height,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: double.infinity,
                                      height: 8,
                                      color: Colors.white,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 2),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 8,
                                      color: Colors.white,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 2),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 8,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      itemCount: 6,
                    ),
                  ),
                ),
                errorImage: Constants.hackerNewsLogoLink,
                backgroundColor: Theme.of(context).canvasColor,
                borderRadius: 0,
                displayDirection: UIDirection.UIDirectionHorizontal,
                removeElevation: true,
                bodyMaxLines: 5,
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
              vertical: 8,
            ),
            child: AbsorbPointer(
              child: SizedBox(
                height: height,
                child: LinkViewHorizontal(
                  showMultiMedia: true,
                  title: story.title,
                  description: text,
                  onTap: (_) {},
                  url: '',
                  radius: 0,
                  imageUri: Constants.hackerNewsLogoLink,
                  bodyMaxLines: 5,
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
              Text(
                story.title,
                style: const TextStyle(fontSize: 15),
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
