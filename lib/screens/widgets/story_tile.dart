import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:shimmer/shimmer.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    required this.showWebPreview,
    required this.showMetadata,
    required this.showUrl,
    required this.story,
    required this.onTap,
    super.key,
    this.hasRead = false,
    this.simpleTileFontSize = 16,
  });

  final bool showWebPreview;
  final bool showMetadata;
  final bool showUrl;
  final bool hasRead;
  final Story story;
  final VoidCallback onTap;
  final double simpleTileFontSize;

  @override
  Widget build(BuildContext context) {
    if (story.hidden) return const SizedBox.shrink();
    if (showWebPreview) {
      final double height = context.storyTileHeight;
      return Semantics(
        label: story.screenReaderLabel,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt12,
          ),
          child: LinkPreview(
            story: story,
            link: story.url,
            isOfflineReading:
                context.read<StoriesBloc>().state.isOfflineReading,
            placeholderWidget: _LinkPreviewPlaceholder(
              height: height,
            ),
            errorImage: Constants.hackerNewsLogoLink,
            backgroundColor: Palette.transparent,
            borderRadius: Dimens.zero,
            removeElevation: true,
            bodyMaxLines: context.storyTileMaxLines,
            errorTitle: story.title,
            titleStyle: TextStyle(
              color: hasRead
                  ? Palette.grey[500]
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
            showMetadata: showMetadata,
            showUrl: showUrl,
            onTap: onTap,
          ),
        ),
      );
    } else {
      return Semantics(
        label: story.screenReaderLabel,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: Dimens.pt12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  height: Dimens.pt8,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: story.title,
                              style: TextStyle(
                                color: hasRead
                                    ? Palette.grey[500]
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                fontWeight: hasRead ? null : FontWeight.w500,
                                fontSize: simpleTileFontSize,
                              ),
                            ),
                            if (showUrl && story.url.isNotEmpty)
                              TextSpan(
                                text: ' (${story.readableUrl})',
                                style: TextStyle(
                                  color: Palette.grey[500],
                                  fontSize: simpleTileFontSize - 4,
                                ),
                              ),
                          ],
                        ),
                        textScaler: MediaQuery.of(context).textScaler,
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
                            color: Palette.grey,
                            fontSize: simpleTileFontSize - 2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(
                  height: Dimens.pt8,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _LinkPreviewPlaceholder extends StatelessWidget {
  const _LinkPreviewPlaceholder({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: SizedBox(
        height: height,
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).primaryColor,
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  right: Dimens.pt5,
                  bottom: Dimens.pt5,
                  top: Dimens.pt5,
                ),
                child: Container(
                  height: height,
                  width: height,
                  color: Palette.white,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: Dimens.pt4,
                    top: Dimens.pt6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: Dimens.pt14,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt4,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt10,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt3,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt10,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt3,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt10,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt3,
                        ),
                      ),
                      Container(
                        width: Dimens.pt40,
                        height: Dimens.pt10,
                        color: Palette.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
