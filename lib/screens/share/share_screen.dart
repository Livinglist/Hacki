import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:hacki/utils/image_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareScreenArgs extends Equatable {
  const ShareScreenArgs({
    required this.item,
    this.parent,
  });

  final Item item;
  final Item? parent;

  @override
  List<Object?> get props => <Object?>[item];
}

class ShareScreen extends StatefulWidget {
  const ShareScreen(
    this.args, {
    super.key,
  });

  final ShareScreenArgs args;

  static const String routeName = 'share';

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _shouldUseRichStoryTile = true;
  bool _shouldShowParent = true;
  bool _shouldShowHackiBanner = true;
  bool _shouldCopyHnLink = true;

  @override
  Widget build(BuildContext context) {
    final Item item = widget.args.item;
    final Item? parent = widget.args.parent;
    final Widget targetWidget = item is Story
        ? StoryTile(
            story: item,
            shouldShowWebPreview: _shouldUseRichStoryTile,
            shouldShowPreviewImage: true,
            shouldShowMetadata: true,
            shouldShowFavicon: true,
            shouldShowUrl: true,
            isExpandedTileEnabled: true,
            onTap: () {},
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_shouldShowParent && parent != null && parent is Story)
                StoryTile(
                  story: parent,
                  shouldShowWebPreview: false,
                  shouldShowPreviewImage: true,
                  shouldShowMetadata: true,
                  shouldShowFavicon: true,
                  shouldShowUrl: true,
                  isExpandedTileEnabled: true,
                  onTap: () {},
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.pt4),
                child: CommentTile(
                  comment: item as Comment,
                  fetchMode: FetchMode.lazy,
                  shouldShowDivider: false,
                  isActionable: false,
                ),
              ),
            ],
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Share as image')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBoxes.pt24,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.pt12,
                  ),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Material(
                      elevation: Dimens.pt8,
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Column(
                          children: <Widget>[
                            SizedBoxes.pt8,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBoxes.pt12,
                                Image.asset(
                                  Constants.hackerNewsLogoPath,
                                  height: Dimens.pt24,
                                  width: Dimens.pt24,
                                  fit: BoxFit.fitWidth,
                                ),
                                SizedBoxes.pt8,
                                Text(
                                  'From Hacker News:',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBoxes.pt8,
                            targetWidget,
                            SizedBoxes.pt8,
                            if (_shouldShowHackiBanner) ...<Widget>[
                              const Divider(
                                height: Dimens.zero,
                              ),
                              SizedBoxes.pt8,
                              Text(
                                '''Shared from Hacki, an open-source Hacker News reader.''',
                                style: TextStyle(
                                  fontSize: TextDimens.pt12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(150),
                                ),
                                textScaler: TextScaler.noScaling,
                                textAlign: TextAlign.center,
                              ),
                              SizedBoxes.pt8,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBoxes.pt24,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save to album'),
                    ),
                    SizedBoxes.pt24,
                    ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ],
                ),
                SizedBoxes.pt12,
                if (item is Story)
                  SwitchListTile(
                    value: _shouldUseRichStoryTile,
                    title: const Text('Show Rich Story Tile'),
                    onChanged: (_) {
                      setState(() {
                        _shouldUseRichStoryTile = !_shouldUseRichStoryTile;
                      });
                    },
                  ),
                if (item is Comment && parent != null && parent is Story)
                  SwitchListTile(
                    value: _shouldShowParent,
                    title: const Text('Show Parent Story'),
                    onChanged: (_) {
                      setState(() {
                        _shouldShowParent = !_shouldShowParent;
                      });
                    },
                  ),
                SwitchListTile(
                  value: _shouldShowHackiBanner,
                  title: const Text('Show Shared from Hacki Banner'),
                  onChanged: (_) {
                    setState(() {
                      _shouldShowHackiBanner = !_shouldShowHackiBanner;
                    });
                  },
                ),
                SwitchListTile(
                  value: _shouldCopyHnLink,
                  title: const Text('Copy link to HN on sharing'),
                  onChanged: (_) {
                    setState(() {
                      _shouldCopyHnLink = !_shouldCopyHnLink;
                    });
                  },
                ),
                SizedBoxes.pt48,
                SizedBoxes.pt48,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final Uint8List? imageBytes =
        await _screenshotController.capture(pixelRatio: 3);
    if (imageBytes == null) return;

    final bool result = await ImageSaver.saveImage(
      imageBytes,
      name: '${widget.args.item.id}_sharing',
    );

    if (mounted) {
      HapticFeedbackUtil.light();
      if (result) {
        context.showSnackBar(content: 'Image saved.');
      } else {
        context.showErrorSnackBar('Failed to save image.');
      }
    }
  }

  Future<void> _share() async {
    try {
      final Uint8List? imageBytes =
          await _screenshotController.capture(pixelRatio: 3);
      if (imageBytes == null) return;

      Rect? rect;
      if (mounted) {
        rect = context.rect;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/story.png');
      await file.writeAsBytes(imageBytes);
      final Uri itemUrl = Uri.parse(
        '${Constants.hackerNewsItemLinkPrefix}${widget.args.item.id}',
      );

      final ShareParams shareParams = ShareParams(
        files: <XFile>[
          XFile(file.path, mimeType: 'image/png'),
        ],
        text: itemUrl.toString(),
        sharePositionOrigin:
            rect ?? const Rect.fromLTWH(0, 0, 100, 100), // Tablet support
      );

      if (_shouldCopyHnLink) {
        await Clipboard.setData(
          ClipboardData(text: itemUrl.toString()),
        );
      }

      await SharePlus.instance.share(shareParams);
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }
}
