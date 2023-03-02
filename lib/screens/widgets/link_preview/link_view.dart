import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:memoize/function_defs.dart';
import 'package:memoize/memoize.dart';

class LinkView extends StatelessWidget {
  LinkView({
    super.key,
    required this.metadata,
    required this.url,
    required this.readableUrl,
    required this.title,
    required this.description,
    required this.onTap,
    required this.showMetadata,
    required bool showUrl,
    required this.bodyMaxLines,
    this.imageUri,
    this.imagePath,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.showMultiMedia = true,
    this.bodyTextOverflow,
    this.isIcon = false,
    this.bgColor,
    this.radius = 0,
  })  : showUrl = showUrl && url.isNotEmpty,
        assert(
          !showMultiMedia ||
              (showMultiMedia && (imageUri != null || imagePath != null)),
          'imageUri or imagePath cannot be null when showMultiMedia is true',
        );

  final String metadata;
  final String url;
  final String readableUrl;
  final String title;
  final String description;
  final String? imageUri;
  final String? imagePath;
  final void Function(String) onTap;
  final TextStyle? titleTextStyle;
  final TextStyle? descriptionTextStyle;
  final bool showMultiMedia;
  final TextOverflow? bodyTextOverflow;
  final int bodyMaxLines;
  final bool isIcon;
  final double radius;
  final Color? bgColor;
  final bool showMetadata;
  final bool showUrl;

  static final double Function(double) _getTitleFontSize =
      memo1(_computeTitleFontSize);

  static double _computeTitleFontSize(double width) {
    double size = width * 0.13;
    if (size > 15) {
      size = 15;
    }
    return size;
  }

  static const double _metadataAbovePadding = 2;
  static const double _bottomPadding = 6;

  static int computeDescriptionMaxLines(
    TextStyle? titleStyle,
    TextStyle? urlStyle,
    TextStyle? metadataStyle,
    TextStyle? descriptionStyle,
    double layoutWidth,
    double layoutHeight,
    double textScaleFactor,
    double titleHeight,
    // ignore: avoid_positional_boolean_parameters
    bool showUrl,
    bool showMetadata,
  ) {
    final Size urlSize = (TextPainter(
      text: TextSpan(
        text: '(url)',
        style: urlStyle,
      ),
      maxLines: 1,
      textScaleFactor: textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size;
    final Size metadataSize = (TextPainter(
      text: TextSpan(
        text: '123metadata',
        style: metadataStyle,
      ),
      maxLines: 1,
      textScaleFactor: textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size;
    final Size descriptionSize = (TextPainter(
      text: TextSpan(
        text: 'DESCRIPTION',
        style: descriptionStyle,
      ),
      maxLines: 1,
      textScaleFactor: textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size;

    final double allPaddings = titleStyle?.fontFamily == Font.robotoSlab.name
        ? Dimens.pt2
        : Dimens.pt4;

    final double height = <double>[
      titleHeight,
      if (showUrl) urlSize.height,
      if (showMetadata) _metadataAbovePadding + metadataSize.height,
      allPaddings,
      _bottomPadding,
    ].reduce((double a, double b) => a + b);

    final double descriptionHeight = layoutHeight - height;

    final int maxLines =
        max(1, (descriptionHeight / descriptionSize.height).floor());

    return maxLines;
  }

  final Func10<
      TextStyle?,
      TextStyle?,
      TextStyle?,
      TextStyle?,
      double,
      double,
      double,
      double,
      bool,
      bool,
      int> getDescriptionMaxLines = memo10(computeDescriptionMaxLines);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;
        final double bodyWidth = layoutWidth - layoutHeight - 8;

        final TextStyle titleStyle = titleTextStyle ??
            TextStyle(
              fontSize: _getTitleFontSize(layoutWidth),
              color: Palette.black,
              fontWeight: FontWeight.bold,
            );
        final TextStyle urlStyle = titleStyle.copyWith(
          color: Palette.grey,
          fontSize: titleStyle.fontSize == null ? 12 : titleStyle.fontSize! - 4,
          fontWeight: FontWeight.w400,
        );
        final TextStyle descriptionStyle = descriptionTextStyle ??
            TextStyle(
              fontSize: _getTitleFontSize(layoutWidth) - 1,
              color: Palette.grey,
              fontWeight: FontWeight.w400,
            );
        final TextStyle metadataStyle = descriptionStyle.copyWith(
          fontSize: descriptionStyle.fontSize == null
              ? TextDimens.pt12
              : descriptionStyle.fontSize! - 2,
        );
        final Size titleSize = (TextPainter(
          text: TextSpan(
            text: title,
            style: titleStyle,
          ),
          maxLines: 2,
          textScaleFactor: MediaQuery.of(context).textScaleFactor,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: bodyWidth))
            .size;

        final int descriptionMaxLines = getDescriptionMaxLines(
          titleStyle,
          urlStyle,
          metadataStyle,
          descriptionStyle,
          bodyWidth,
          layoutHeight,
          MediaQuery.of(context).textScaleFactor,
          titleSize.height,
          showUrl,
          showMetadata,
        );

        return InkWell(
          onTap: () => onTap(url),
          child: Row(
            children: <Widget>[
              if (showMultiMedia)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                    top: 5,
                    bottom: 5,
                  ),
                  child: SizedBox(
                    height: layoutHeight,
                    width: layoutHeight,
                    child: (imageUri?.isEmpty ?? true) && imagePath != null
                        ? Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUri!,
                            fit: isIcon ? BoxFit.scaleDown : BoxFit.fitWidth,
                            memCacheHeight: layoutHeight.toInt() * 4,
                            errorWidget: (BuildContext context, _, __) {
                              return Image.asset(
                                Constants.hackerNewsLogoPath,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                )
              else
                const SizedBox(width: Dimens.pt5),
              SizedBox(
                height: layoutHeight,
                width: layoutWidth - layoutHeight - 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily ==
                                  Font.robotoSlab.name
                              ? Dimens.pt2
                              : Dimens.pt4,
                    ),
                    Text(
                      title,
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (showUrl)
                      Text(
                        '($readableUrl)',
                        textAlign: TextAlign.left,
                        style: urlStyle,
                        overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (showMetadata) ...<Widget>[
                      const SizedBox(
                        height: _metadataAbovePadding,
                      ),
                      Text(
                        metadata,
                        textAlign: TextAlign.left,
                        style: metadataStyle,
                        overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      style: descriptionStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: descriptionMaxLines,
                    ),
                    const SizedBox(
                      height: _bottomPadding,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
