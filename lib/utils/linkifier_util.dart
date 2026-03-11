import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';

abstract class LinkifierUtil {
  static const LinkifyOptions linkifyOptions = LinkifyOptions(humanize: false);

  static List<LinkifyElement> linkify(
    String text, {
    List<Linkifier> extraLinkifiers = const <Linkifier>[],
  }) {
    final List<Linkifier> linkifiers = <Linkifier>[
      ...defaultLinkifiers,
      ...extraLinkifiers,
    ];
    List<LinkifyElement> elements = <LinkifyElement>[TextElement(text)];

    if (text.isEmpty) {
      return <LinkifyElement>[];
    }

    if (linkifiers.isEmpty) {
      return elements;
    }

    for (final Linkifier linkifier in linkifiers) {
      elements = linkifier.parse(elements, linkifyOptions);
    }

    return elements;
  }
}
