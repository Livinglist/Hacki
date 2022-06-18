import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:shimmer/shimmer.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    super.key,
    this.hasRead = false,
    required this.showWebPreview,
    required this.showMetadata,
    required this.story,
    required this.onTap,
    this.simpleTileFontSize = 16,
  });

  final bool showWebPreview;
  final bool showMetadata;
  final bool hasRead;
  final Story story;
  final VoidCallback onTap;
  final double simpleTileFontSize;

  @override
  Widget build(BuildContext context) {
    if (showWebPreview) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool showSmallerPreviewPic =
          screenWidth > 428.0 && screenWidth < 850;
      final double height = showSmallerPreviewPic
          ? 100.0
          : (MediaQuery.of(context).size.height * 0.14).clamp(118.0, 140.0);

      return TapDownWrapper(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: AbsorbPointer(
            child: LinkPreview(
              story: story,
              link: story.url,
              offlineReading: context.read<StoriesBloc>().state.offlineReading,
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
              showMetadata: showMetadata,
            ),
          ),
        ),
      );
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
              if (showMetadata)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        story.metadata,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: simpleTileFontSize - 2,
                        ),
                        maxLines: 1,
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
