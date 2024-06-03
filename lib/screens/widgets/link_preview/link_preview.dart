import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/link_preview/link_view.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';

class LinkPreview extends StatefulWidget {
  const LinkPreview({
    required this.link,
    required this.story,
    required this.onTap,
    required this.showMetadata,
    required this.showUrl,
    required this.isOfflineReading,
    required this.hasRead,
    super.key,
    this.cache = const Duration(days: 30),
    this.showMultimedia = true,
    this.backgroundColor = const Color.fromRGBO(235, 235, 235, 1),
    this.bodyMaxLines = 3,
    this.bodyTextOverflow = TextOverflow.ellipsis,
    this.placeholderWidget,
    this.errorWidget,
    this.errorBody,
    this.errorImage,
    this.errorTitle,
    this.borderRadius,
    this.boxShadow,
    this.removeElevation = false,
  });

  final Story story;
  final VoidCallback onTap;
  final bool hasRead;

  /// Web address (Url that need to be parsed)
  /// For IOS & Web, only HTTP and HTTPS are support
  /// For Android, all urls are supported
  final String link;

  /// Customize background colour
  /// Defaults to `Color.fromRGBO(235, 235, 235, 1)`
  final Color? backgroundColor;

  /// Widget that need to be shown when
  /// plugin is trying to fetch metadata
  /// If not given anything then default one will be shown
  final Widget? placeholderWidget;

  /// Widget that need to be shown if something goes wrong
  /// Defaults to plain container with given background colour
  /// If the issue is know then we will show customized UI
  /// Other options of error params are used
  final Widget? errorWidget;

  /// Title that need to be shown if something goes wrong
  /// Defaults to `Something went wrong!`
  final String? errorTitle;

  /// Body that need to be shown if something goes wrong
  /// Defaults to `Oops! Unable to parse the url.
  /// We have sent feedback to our developers & we will
  /// try to fix this in our next release. Thanks!`
  final String? errorBody;

  /// Image that will be shown if something goes wrong
  /// & when multimedia enabled & no meta data is available
  /// Defaults to `A semi-soccer ball image that looks like crying`
  final String? errorImage;

  /// Give the overflow type for body text (Description)
  /// Defaults to `TextOverflow.ellipsis`
  final TextOverflow bodyTextOverflow;

  /// Give the limit to body text (Description)
  /// Defaults to `3`
  final int bodyMaxLines;

  /// Cache result time, default cache `30 days`
  /// Works only for IOS & not for android
  final Duration cache;

  /// Show or Hide image if available defaults to `true`
  final bool showMultimedia;

  /// BorderRadius for the card. Defaults to `12`
  final double? borderRadius;

  /// To remove the card elevation set it to `true`
  /// Default value is `false`
  final bool removeElevation;

  /// Box shadow for the card. Defaults to
  /// `[BoxShadow(blurRadius: 3, color: Palette.grey)]`
  final List<BoxShadow>? boxShadow;

  final bool showMetadata;
  final bool showUrl;
  final bool isOfflineReading;

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  InfoBase? _info;
  String? _errorTitle;
  String? _errorBody;
  bool _loading = false;

  @override
  void initState() {
    _errorTitle = widget.errorTitle ?? Constants.errorMessage;
    _errorBody = widget.errorBody ??
        'Oops! Unable to parse the url. We have '
            'sent feedback to our developers & '
            'we will try to fix this in our next release. Thanks!';

    _loading = true;
    _getInfo();

    super.initState();
  }

  Future<void> _getInfo() async {
    _info = await WebAnalyzer.getInfo(
      story: widget.story,
      cache: widget.cache,
      offlineReading: widget.isOfflineReading,
    );

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildLinkContainer(
    double height, {
    String? title = '',
    String? desc = '',
    String? imageUri = '',
    String? iconUri = '',
    bool isIcon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? Dimens.pt12,
        ),
        boxShadow: widget.removeElevation
            ? <BoxShadow>[]
            : widget.boxShadow ??
                <BoxShadow>[
                  const BoxShadow(blurRadius: 3, color: Palette.grey),
                ],
      ),
      height: height,
      child: LinkView(
        key: widget.key ?? Key(widget.link),
        metadata: widget.story.simpleMetadata,
        url: widget.link,
        readableUrl: widget.story.readableUrl,
        title: widget.story.title,
        description: desc ?? title ?? 'no comment yet.',
        imageUri: imageUri,
        iconUri: iconUri,
        imagePath: Constants.hackerNewsLogoPath,
        onTap: widget.onTap,
        hasRead: widget.hasRead,
        bodyTextOverflow: widget.bodyTextOverflow,
        bodyMaxLines: widget.bodyMaxLines,
        showMultiMedia: widget.showMultimedia,
        isIcon: isIcon,
        bgColor: widget.backgroundColor,
        radius: widget.borderRadius ?? 12,
        showMetadata: widget.showMetadata,
        showUrl: widget.showUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget loadingWidget = widget.placeholderWidget ??
        Container(
          height: context.storyTileHeight,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? Dimens.pt12,
            ),
            color: Palette.grey[200],
          ),
          alignment: Alignment.center,
          child: const Text('Fetching data...'),
        );

    Widget loadedWidget;

    final WebInfo? info = _info as WebInfo?;
    loadedWidget = _info == null
        ? _buildLinkContainer(
            context.storyTileHeight,
            title: _errorTitle,
            desc: _errorBody,
            imageUri: null,
            iconUri: null,
          )
        : _buildLinkContainer(
            context.storyTileHeight,
            title: _errorTitle,
            desc: WebAnalyzer.isNotEmpty(info!.description)
                ? info.description
                : _errorBody,
            imageUri: widget.showMultimedia ? info.image : null,
            iconUri: widget.showMultimedia ? info.icon : null,
          );

    return AnimatedCrossFade(
      firstChild: loadingWidget,
      secondChild: loadedWidget,
      crossFadeState:
          _loading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: AppDurations.ms500,
    );
  }
}
