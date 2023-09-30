import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';

abstract class LinkifierUtil {
  static const LinkifyOptions linkifyOptions = LinkifyOptions(humanize: false);

  static List<LinkifyElement> linkify(String text) {
    List<LinkifyElement> list = <LinkifyElement>[TextElement(text)];

    if (text.isEmpty) {
      return <LinkifyElement>[];
    }

    if (defaultLinkifiers.isEmpty) {
      return list;
    }

    for (final Linkifier linkifier in defaultLinkifiers) {
      list = linkifier.parse(list, linkifyOptions);
    }

    return list;
  }
}
