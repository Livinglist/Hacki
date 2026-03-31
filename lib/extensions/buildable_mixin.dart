import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/utils/utils.dart';

///
/// Convert [Item] to [Buildable] which contains [LinkifyElement]
/// that can be rendered in [Linkify] widget.
///
mixin BuildableMixin {
  Future<Item?> toBuildable(
    Item? item, {
    String? withHighlightedText,
  }) async {
    if (item == null) return null;

    switch (item.runtimeType) {
      case Comment:
        return toBuildableComment(
          item as Comment,
          withHighlightedText: withHighlightedText,
        );
      case Story:
        return toBuildableStory(item as Story);
    }

    return null;
  }

  Future<BuildableComment?> toBuildableComment(
    Comment? comment, {
    String? withHighlightedText,
  }) async {
    if (comment == null) return null;

    final List<LinkifyElement> elements = await Isolate.run(
      () => LinkifierUtil.linkify(
        comment.text,
        extraLinkifiers: <Linkifier>[
          if (withHighlightedText != null && withHighlightedText.isNotEmpty)
            HighlightLinkifier(highlightedText: withHighlightedText),
        ],
      ),
    );

    final BuildableComment buildableComment =
        BuildableComment.fromComment(comment, elements: elements);

    return buildableComment;
  }

  Future<BuildableStory?> toBuildableStory(Story? story) async {
    if (story == null) {
      return null;
    } else if (story.text.isEmpty) {
      return BuildableStory.fromTitleOnlyStory(story);
    }

    final List<LinkifyElement> elements =
        await compute<String, List<LinkifyElement>>(
      LinkifierUtil.linkify,
      story.text,
    );

    final BuildableStory buildableStory =
        BuildableStory.fromStory(story, elements: elements);

    return buildableStory;
  }
}
