import 'package:hacki/screens/widgets/custom_linkify/linkifiers/linkifiers.dart';
import 'package:linkify/linkify.dart';

abstract class LinkifierUtil {
  static const LinkifyOptions linkifyOptions = LinkifyOptions(humanize: false);

  static List<LinkifyElement> linkify(String text) {
    const List<Linkifier> linkifiers = <Linkifier>[
      UrlLinkifier(),
      EmailLinkifier(),
      QuoteLinkifier(),
      EmphasisLinkifier(),
    ];
    List<LinkifyElement> list = <LinkifyElement>[TextElement(text)];

    if (text.isEmpty) {
      return <LinkifyElement>[];
    }

    if (linkifiers.isEmpty) {
      return list;
    }

    for (final Linkifier linkifier in linkifiers) {
      list = linkifier.parse(list, linkifyOptions);
    }

    return list;
  }
}
