import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/styles/styles.dart';

class LinkView extends StatelessWidget {
  const LinkView({
    super.key,
    required this.metadata,
    required this.url,
    required this.title,
    required this.description,
    required this.onTap,
    required this.showMetadata,
    this.imageUri,
    this.imagePath,
    this.titleTextStyle,
    this.bodyTextStyle,
    this.showMultiMedia = true,
    this.bodyTextOverflow,
    this.bodyMaxLines,
    this.isIcon = false,
    this.bgColor,
    this.radius = 0,
  }) : assert(
          !showMultiMedia ||
              (showMultiMedia && (imageUri != null || imagePath != null)),
          'imageUri or imagePath cannot be null when showMultiMedia is true',
        );

  final String metadata;
  final String url;
  final String title;
  final String description;
  final String? imageUri;
  final String? imagePath;
  final Function(String) onTap;
  final TextStyle? titleTextStyle;
  final TextStyle? bodyTextStyle;
  final bool showMultiMedia;
  final TextOverflow? bodyTextOverflow;
  final int? bodyMaxLines;
  final bool isIcon;
  final double radius;
  final Color? bgColor;
  final bool showMetadata;

  double computeTitleFontSize(double width) {
    double size = width * 0.13;
    if (size > 15) {
      size = 15;
    }
    return size;
  }

  int computeTitleLines(double layoutHeight) {
    return layoutHeight >= 100 ? 2 : 1;
  }

  int computeBodyLines(double layoutHeight) {
    int lines = 1;
    if (layoutHeight > 40) {
      lines += (layoutHeight - 40.0) ~/ 15.0;
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;

        final TextStyle _titleFontSize = titleTextStyle ??
            TextStyle(
              fontSize: computeTitleFontSize(layoutWidth),
              color: Palette.black,
              fontWeight: FontWeight.bold,
            );
        final TextStyle _bodyFontSize = bodyTextStyle ??
            TextStyle(
              fontSize: computeTitleFontSize(layoutWidth) - 1,
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
                    right: 5,
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
                            errorWidget: (BuildContext context, _, dynamic __) {
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
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildTitleContainer(
                        _titleFontSize,
                        computeTitleLines(layoutHeight),
                      ),
                      _buildBodyContainer(
                        _bodyFontSize,
                        computeBodyLines(layoutHeight),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleContainer(TextStyle _titleTS, int _maxLines) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 3, 0),
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Text(
              title,
              style: _titleTS,
              overflow: TextOverflow.ellipsis,
              maxLines: _maxLines,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContainer(TextStyle _bodyTS, int _maxLines) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
        child: Column(
          children: <Widget>[
            if (showMetadata)
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  metadata,
                  textAlign: TextAlign.left,
                  style: _bodyTS.copyWith(
                    fontSize:
                        _bodyTS.fontSize == null ? 12 : _bodyTS.fontSize! - 2,
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
                  style: _bodyTS,
                  overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                  maxLines:
                      (bodyMaxLines ?? _maxLines) - (showMetadata ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
