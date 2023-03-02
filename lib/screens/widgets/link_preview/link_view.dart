import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/link_preview/models/models.dart';
import 'package:hacki/styles/styles.dart';
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
  static late TextStyle urlStyle;
  static late TextStyle metadataStyle;
  static late TextStyle descriptionStyle;

  static Map<MaxLineComputationParams, int> computationCache =
      <MaxLineComputationParams, int>{};

  static int getDescriptionMaxLines(
    MaxLineComputationParams params,
    TextStyle titleStyle,
  ) {
    if (computationCache.containsKey(params)) {
      return computationCache[params]!;
    }

    urlStyle = titleStyle.copyWith(
      color: Palette.grey,
      fontSize: titleStyle.fontSize == null ? 12 : titleStyle.fontSize! - 4,
      fontWeight: FontWeight.w400,
      fontFamily: params.fontFamily,
    );
    descriptionStyle = TextStyle(
      fontSize: _getTitleFontSize(params.layoutWidth) - 1,
      color: Palette.grey,
      fontWeight: FontWeight.w400,
      fontFamily: params.fontFamily,
    );
    metadataStyle = descriptionStyle.copyWith(
      fontSize: descriptionStyle.fontSize == null
          ? TextDimens.pt12
          : descriptionStyle.fontSize! - 2,
      fontFamily: params.fontFamily,
    );

    final double urlHeight = (TextPainter(
      text: TextSpan(
        text: '(url)',
        style: urlStyle,
      ),
      maxLines: 1,
      textScaleFactor: params.textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .height;
    final double metadataHeight = (TextPainter(
      text: TextSpan(
        text: '123metadata',
        style: metadataStyle,
      ),
      maxLines: 1,
      textScaleFactor: params.textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .height;
    final double descriptionHeight = (TextPainter(
      text: TextSpan(
        text: 'DESCRIPTION',
        style: descriptionStyle,
      ),
      maxLines: 1,
      textScaleFactor: params.textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .height;

    final double allPaddings =
        params.fontFamily == Font.robotoSlab.name ? Dimens.pt2 : Dimens.pt4;

    final double height = <double>[
      params.titleHeight,
      if (params.showUrl) urlHeight,
      if (params.showMetadata) _metadataAbovePadding + metadataHeight,
      allPaddings,
      _bottomPadding,
    ].reduce((double a, double b) => a + b);

    final double descriptionAllowedHeight = params.layoutHeight - height;

    final int maxLines =
        max(1, (descriptionAllowedHeight / descriptionHeight).floor());

    computationCache[params] = maxLines;

    return maxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;
        final double bodyWidth = layoutWidth - layoutHeight - 8;
        final String? fontFamily =
            Theme.of(context).primaryTextTheme.bodyMedium?.fontFamily;
        final double textScaleFactor = MediaQuery.of(context).textScaleFactor;

        final TextStyle titleStyle = titleTextStyle ??
            TextStyle(
              fontSize: _getTitleFontSize(layoutWidth),
              color: Palette.black,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            );
        final double titleHeight = (TextPainter(
          text: TextSpan(
            text: title,
            style: titleStyle,
          ),
          maxLines: 2,
          textScaleFactor: textScaleFactor,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: bodyWidth))
            .size
            .height;

        final int descriptionMaxLines = getDescriptionMaxLines(
          MaxLineComputationParams(
            fontFamily ?? Font.roboto.name,
            bodyWidth,
            layoutHeight,
            titleHeight,
            textScaleFactor,
            showUrl,
            showMetadata,
          ),
          titleStyle,
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
