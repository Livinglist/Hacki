import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    required this.shouldShowWebPreview,
    required this.shouldShowPreviewImage,
    required this.shouldShowMetadata,
    required this.shouldShowFavicon,
    required this.shouldShowUrl,
    required this.isExpandedTileEnabled,
    required this.story,
    required this.onTap,
    super.key,
    this.index,
    this.isIndexedStoryTileEnabled = false,
    this.hasRead = false,
    this.simpleTileFontSize = 16,
  }) : assert(
          !isIndexedStoryTileEnabled ||
              (isIndexedStoryTileEnabled && index != null),
          '`index` cannot be null when `shouldShowIndex` is enabled.',
        );

  final bool shouldShowWebPreview;
  final bool shouldShowPreviewImage;
  final bool shouldShowMetadata;
  final bool shouldShowFavicon;
  final bool shouldShowUrl;
  final bool hasRead;
  final bool isExpandedTileEnabled;
  final bool isIndexedStoryTileEnabled;
  final Story story;
  final int? index;
  final VoidCallback onTap;
  final double simpleTileFontSize;

  @override
  Widget build(BuildContext context) {
    if (story.hidden) return const SizedBox.shrink();
    if (shouldShowWebPreview) {
      final double height = context.storyTileHeight;
      return Semantics(
        label: story.screenReaderLabel,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TapDownWrapper(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          if (isIndexedStoryTileEnabled && index != null)
                            TextSpan(
                              text: '#${index! + 1} ',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          TextSpan(
                            text: story.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: hasRead
                                      ? Theme.of(context).readGrey
                                      : null,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (shouldShowUrl && story.readableUrl.isNotEmpty)
                            TextSpan(
                              text: ' (${story.readableUrl})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: hasRead
                                        ? Theme.of(context).readGrey
                                        : null,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (shouldShowMetadata)
                      Text(
                        story.metadata,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasRead
                                  ? Theme.of(context).readGrey
                                  : Theme.of(context).metadataColor,
                            ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              LinkPreview(
                story: story,
                link: story.url,
                isOfflineReading:
                    context.read<StoriesBloc>().state.isOfflineReading,
                isExpandedTileEnabled: isExpandedTileEnabled,
                placeholderWidget: _LinkPreviewPlaceholder(
                  height: height,
                  shouldShowPreviewImage: shouldShowPreviewImage,
                ),
                errorImage: Constants.hackerNewsLogoLink,
                backgroundColor: Palette.transparent,
                borderRadius: Dimens.zero,
                removeElevation: true,
                bodyMaxLines: context.storyTileMaxLines,
                errorTitle: story.title,
                hasRead: hasRead,
                shouldShowMetadata: shouldShowMetadata,
                shouldShowMultimedia: shouldShowPreviewImage,
                shouldShowUrl: shouldShowUrl,
                onTap: onTap,
              ),
            ],
          ),
        ),
      );
    } else {
      return Semantics(
        label: story.screenReaderLabel,
        excludeSemantics: true,
        child: TapDownWrapper(
          onTap: onTap,
          onLongPress: () {
            if (story.url.isNotEmpty) {
              LinkUtil.launch(
                story.url,
                context,
                shouldUseReader:
                    context.read<PreferenceCubit>().state.isReaderEnabled,
                isOfflineReading:
                    context.read<StoriesBloc>().state.isOfflineReading,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: Dimens.pt12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (shouldShowFavicon) ...<Widget>[
                  if (story.url.isNotEmpty)
                    SizedBox(
                      height: Dimens.pt20,
                      width: Dimens.pt24,
                      child: Center(
                        child: CachedNetworkImage(
                          fit: BoxFit.fitHeight,
                          imageUrl: Constants.favicon(story.url),
                          errorWidget: (_, __, ___) {
                            return const Icon(
                              Icons.public,
                              size: Dimens.pt20,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: Dimens.pt20,
                      width: Dimens.pt24,
                      child: Center(
                        child: Image.asset(
                          Constants.hackerNewsLogoPath,
                          fit: BoxFit.fitWidth,
                          height: Dimens.pt20,
                          width: Dimens.pt20,
                        ),
                      ),
                    ),
                  const SizedBox(
                    width: Dimens.pt8,
                  ),
                ],
                Expanded(
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
                                  if (isIndexedStoryTileEnabled &&
                                      index != null)
                                    TextSpan(
                                      text: '#${index! + 1} ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  TextSpan(
                                    text: story.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: hasRead
                                              ? Theme.of(context).readGrey
                                              : null,
                                          fontWeight:
                                              hasRead ? null : FontWeight.bold,
                                        ),
                                  ),
                                  if (shouldShowUrl && story.url.isNotEmpty)
                                    TextSpan(
                                      text: ' (${story.readableUrl})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: hasRead
                                                ? Theme.of(context).readGrey
                                                : null,
                                          ),
                                    ),
                                ],
                              ),
                              textScaler: MediaQuery.of(context).textScaler,
                            ),
                          ),
                        ],
                      ),
                      if (shouldShowMetadata)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                story.metadataWithShortTimeAgoString,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: hasRead
                                          ? Theme.of(context).readGrey
                                          : Theme.of(context).metadataColor,
                                    ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(
                        height: Dimens.pt14,
                      ),
                    ],
                  ),
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
    required this.shouldShowPreviewImage,
  });

  final double height;
  final bool shouldShowPreviewImage;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: SizedBox(
        height: shouldShowPreviewImage ? height : null,
        child: Shimmer.fromColors(
          baseColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          highlightColor: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (shouldShowPreviewImage)
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
                  padding: EdgeInsets.only(
                    left: shouldShowPreviewImage ? Dimens.pt4 : Dimens.zero,
                    top: Dimens.pt6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: Dimens.pt12,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt4,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt12,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt4,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt12,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt4,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: Dimens.pt12,
                        color: Palette.white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimens.pt4,
                        ),
                      ),
                      Container(
                        width: Dimens.pt40,
                        height: Dimens.pt12,
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
