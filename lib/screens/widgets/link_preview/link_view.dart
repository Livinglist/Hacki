import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_util.dart';
import 'package:memoize/function_defs.dart';
import 'package:memoize/memoize.dart';

class LinkView extends StatelessWidget {
  LinkView({
    required this.metadata,
    required this.url,
    required this.readableUrl,
    required this.title,
    required this.description,
    required this.onTap,
    required this.showMetadata,
    required bool showUrl,
    required this.bodyMaxLines,
    super.key,
    this.imageUri,
    this.imagePath,
    this.showMultiMedia = true,
    this.bodyTextOverflow,
    this.isIcon = false,
    this.hasRead = false,
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
  final VoidCallback onTap;
  final bool showMultiMedia;
  final bool hasRead;
  final TextOverflow? bodyTextOverflow;
  final int bodyMaxLines;
  final bool isIcon;
  final double radius;
  final Color? bgColor;
  final bool showMetadata;
  final bool showUrl;

  static final Func3<TextScaler, TextStyle?, double, int> _computeMaxLines =
      memo3((TextScaler textScaler, TextStyle? style, double layoutHeight) {
    final Size size = (TextPainter(
      text: TextSpan(text: 'ABCDEFG', style: style),
      maxLines: 1,
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
    )..layout())
        .size;

    final int maxLines = max(1, (layoutHeight / size.height).floor());

    return maxLines;
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;

        final TextStyle? style = Theme.of(context).textTheme.bodyMedium;

        final int maxLines = _computeMaxLines(
          MediaQuery.of(context).textScaler,
          style,
          layoutHeight,
        );

        return Row(
          children: <Widget>[
            if (showMultiMedia)
              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                  top: 5,
                  bottom: 5,
                ),
                child: TapDownWrapper(
                  onTap: () {
                    if (url.isNotEmpty) {
                      LinkUtil.launch(
                        url,
                        context,
                        useHackiForHnLink: false,
                        offlineReading:
                            context.read<StoriesBloc>().state.isOfflineReading,
                      );
                    } else {
                      onTap();
                    }
                  },
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
                            cacheKey: imageUri,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                r'¯\_(ツ)_/¯',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              )
            else
              const SizedBox(width: Dimens.pt5),
            TapDownWrapper(
              onTap: onTap,
              child: SizedBox(
                height: layoutHeight,
                width: layoutWidth - layoutHeight - 8,
                child: Text(
                  description,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasRead ? Theme.of(context).readGrey : null,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
