import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/stories/stories_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_util.dart';

class ImageWrapText extends StatelessWidget {
  const ImageWrapText({
    required this.text,
    required this.image,
    required this.onTap,
    required this.url,
    required this.hasRead,
    super.key,
    this.imageHeight = 200,
    this.imageWidth = 200,
    this.gap = 12,
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

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double rightWidth = math.max(0, maxWidth - imageWidth - gap);

        // 先测出行高（用一小段字符即可）
        final double lineHeight = _measureLineHeight(effectiveStyle, context);

        // 图片高度能放下多少行文字（至少 1 行）
        final int linesBesideImage =
            math.max(1, (imageHeight / lineHeight).floor());

        // 计算 text 在右侧区域、限定行数下能放多少字符，得到切分点
        final int splitIndex = _findSplitIndex(
          text: text,
          style: effectiveStyle,
          context: context,
          width: rightWidth,
          maxLines: linesBesideImage,
        );

        final String firstPart = text.substring(0, splitIndex).trimRight();
        final String secondPart = text.substring(splitIndex).trimLeft();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: Dimens.pt6,
                  ),
                  child: TapDownWrapper(
                    onTap: () {
                      if (url.isNotEmpty) {
                        LinkUtil.launch(
                          url,
                          context,
                          useHackiForHnLink: false,
                          useReader: context
                              .read<PreferenceCubit>()
                              .state
                              .isReaderEnabled,
                          offlineReading: context
                              .read<StoriesBloc>()
                              .state
                              .isOfflineReading,
                        );
                      } else {
                        onTap();
                      }
                    },
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: image,
                    ),
                  ),
                ),
                SizedBox(width: gap),
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
              ],
            ),
            if (secondPart.isNotEmpty) ...<Widget>[
              SizedBoxes.pt8,
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
    return tp.height; // 单行高度
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

      // didExceedMaxLines 为 true 表示放不下
      return !tp.didExceedMaxLines;
    }

    // 二分找最大可放下的字符数
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
