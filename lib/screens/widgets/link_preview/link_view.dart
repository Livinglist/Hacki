import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
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
    this.bodyTextStyle,
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
  final TextStyle? bodyTextStyle;
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

  static final int Function(double) _getTitleLines = memo1(_computeTitleLines);

  static int _computeTitleLines(double layoutHeight) {
    return layoutHeight >= 100 ? 2 : 1;
  }

  static final int Function(int, bool, bool, String?) _getBodyLines =
      memo4(_computeBodyLines);

  static int _computeBodyLines(
    int bodyMaxLines,
    bool showMetadata,
    bool showUrl,
    String? fontFamily,
  ) {
    final int maxLines = bodyMaxLines -
        (showMetadata ? 1 : 0) -
        (showUrl ? 1 : 0) +
        (fontFamily == Font.ubuntuMono.name ? 1 : 0);
    return maxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;

        final TextStyle titleFontStyle = titleTextStyle ??
            TextStyle(
              fontSize: _getTitleFontSize(layoutWidth),
              color: Palette.black,
              fontWeight: FontWeight.bold,
            );
        final TextStyle bodyFontStyle = bodyTextStyle ??
            TextStyle(
              fontSize: _getTitleFontSize(layoutWidth) - 1,
              color: Palette.grey,
              fontWeight: FontWeight.w400,
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
                const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                        top: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontFamily ==
                                Font.robotoSlab.name
                            ? 2
                            : 4,
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              style: titleFontStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: _getTitleLines(layoutHeight),
                            ),
                          ),
                          if (showUrl && url.isNotEmpty)
                            Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '($readableUrl)',
                                textAlign: TextAlign.left,
                                style: titleFontStyle.copyWith(
                                  color: Palette.grey,
                                  fontSize: titleFontStyle.fontSize == null
                                      ? 12
                                      : titleFontStyle.fontSize! - 4,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow:
                                    bodyTextOverflow ?? TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showMetadata)
                      Container(
                        alignment: Alignment.topLeft,
                        margin: const EdgeInsets.only(top: 2),
                        child: Text(
                          metadata,
                          textAlign: TextAlign.left,
                          style: bodyFontStyle.copyWith(
                            fontSize: bodyFontStyle.fontSize == null
                                ? 12
                                : bodyFontStyle.fontSize! - 2,
                          ),
                          overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          description,
                          textAlign: TextAlign.left,
                          style: bodyFontStyle,
                          overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                          maxLines: _getBodyLines(
                            bodyMaxLines,
                            showMetadata,
                            showUrl,
                            Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                      ),
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
