import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/stories/stories_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_utils.dart';

class ImageWrapText extends StatelessWidget {
  const ImageWrapText({
    required this.text,
    required this.image,
    required this.onTap,
    required this.url,
    required this.hasRead,
    required this.isImageLeftAligned,
    super.key,
    this.imageHeight = 200,
    this.imageWidth = 200,
    this.gap = 8,
    this.style,
  });

  final String text;
  final Widget image;
  final double imageHeight;
  final double imageWidth;
  final double gap;
  final TextStyle? style;
  final String url;
  final VoidCallback onTap;
  final bool hasRead;
  final bool isImageLeftAligned;

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double rightWidth = math.max(0, maxWidth - imageWidth - gap);

        /// Measure the line height.
        final double lineHeight = _measureLineHeight(effectiveStyle, context);

        /// Check how many lines can be fit in the image height.
        final int linesBesideImage =
            math.max(1, (imageHeight / lineHeight).floor());

        /// Get the index of text where the upper and
        /// lower part should be split.
        final int splitIndex = _findSplitIndex(
          text: text,
          style: effectiveStyle,
          context: context,
          width: rightWidth,
          maxLines: linesBesideImage,
        );

        final String firstPart = text.substring(0, splitIndex).trimRight();
        final String secondPart = text.substring(splitIndex).trimLeft();
        final Widget imageWidget = Padding(
          padding: const EdgeInsets.only(
            top: Dimens.pt5,
          ),
          child: TapDownWrapper(
            onTap: () {
              if (url.isNotEmpty) {
                LinkUtils.launch(
                  url,
                  context,
                  shouldUseHackiForHnLink: false,
                  shouldUseReader:
                      context.read<PreferenceCubit>().state.isReaderEnabled,
                  isOfflineReading:
                      context.read<StoriesBloc>().state.isOfflineReading,
                );
              } else {
                onTap();
              }
            },
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              width: imageWidth,
              height: imageHeight - 8,
              child: image,
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isImageLeftAligned) ...<Widget>[
                  imageWidget,
                  SizedBox(width: gap),
                ],
                Expanded(
                  child: TapDownWrapper(
                    onTap: onTap,
                    child: Text(
                      firstPart,
                      style: effectiveStyle.copyWith(
                        color: hasRead ? Theme.of(context).readGrey : null,
                      ),
                    ),
                  ),
                ),
                if (!isImageLeftAligned) ...<Widget>[
                  SizedBox(width: gap),
                  imageWidget,
                ],
              ],
            ),
            if (secondPart.isNotEmpty) ...<Widget>[
              TapDownWrapper(
                onTap: onTap,
                child: Text(
                  secondPart,
                  style: effectiveStyle.copyWith(
                    color: hasRead ? Theme.of(context).readGrey : null,
                  ),
                  maxLines: 20,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static double _measureLineHeight(TextStyle style, BuildContext context) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: 'A', style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return tp.height;
  }

  static int _findSplitIndex({
    required String text,
    required TextStyle style,
    required BuildContext context,
    required double width,
    required int maxLines,
  }) {
    if (width <= 0) return 0;
    if (text.isEmpty) return 0;

    int lo = 0;
    int hi = text.length;

    bool fits(int mid) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: text.substring(0, mid), style: style),
        textDirection: Directionality.of(context),
        maxLines: maxLines,
        ellipsis: '\u2026',
      )..layout(maxWidth: width);

      return !tp.didExceedMaxLines;
    }

    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
