import 'package:hacki/models/item/buildable.dart';
import 'package:hacki/models/item/story.dart';
import 'package:linkify/linkify.dart';

/// [BuildableStory] is a subtype of [Story] which stores
/// the corresponding [LinkifyElement] for faster widget building.
class BuildableStory extends Story with Buildable {
  const BuildableStory({
    required super.id,
    required super.time,
    required super.score,
    required super.by,
    required super.text,
    required super.kids,
    required super.descendants,
    required super.title,
    required super.type,
    required super.url,
    required super.parts,
    required this.elements,
  });

  BuildableStory.fromStory(Story story, {required this.elements})
      : super(
          id: story.id,
          time: story.time,
          score: story.score,
          by: story.by,
          text: story.text,
          kids: story.kids,
          descendants: story.descendants,
          title: story.title,
          type: story.type,
          url: story.url,
          parts: story.parts,
        );

  BuildableStory.fromTitleOnlyStory(Story story)
      : this.fromStory(
          story,
          elements: const <LinkifyElement>[],
        );

  @override
  final List<LinkifyElement> elements;
}
