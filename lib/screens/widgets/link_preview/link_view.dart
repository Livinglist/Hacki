import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_util.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double layoutWidth = constraints.biggest.width;
        final double layoutHeight = constraints.biggest.height;

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
                            memCacheHeight: layoutHeight.toInt() * 4,
                            errorWidget: (BuildContext context, _, __) {
                              return Image.asset(
                                Constants.hackerNewsLogoPath,
                                fit: BoxFit.cover,
                              );
                            },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: Dimens.pt2,
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            height: 1.2,
                            color: hasRead ? Theme.of(context).readGrey : null,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (showUrl)
                      Text(
                        '($readableUrl)',
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: hasRead
                                  ? Theme.of(context).readGrey
                                  : Theme.of(context)
                                      .unreadGrey
                                      .withOpacity(0.5),
                            ),
                        overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    if (showMetadata)
                      Text(
                        metadata,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: hasRead
                                  ? Theme.of(context).readGrey
                                  : Theme.of(context).unreadGrey,
                            ),
                        overflow: bodyTextOverflow ?? TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    Flexible(
                      child: Text(
                        description,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasRead
                                  ? Theme.of(context).readGrey
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.9),
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension on ThemeData {
  Color get readGrey => colorScheme.onSurface.withOpacity(0.4);

  Color get unreadGrey => colorScheme.onSurface.withOpacity(0.8);
}
