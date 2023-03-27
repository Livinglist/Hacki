import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class ItemText extends StatelessWidget {
  const ItemText({
    super.key,
    required this.item,
    this.onTap,
  });

  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final PreferenceState prefState = context.read<PreferenceCubit>().state;
    final TextStyle style = TextStyle(
      fontSize: prefState.fontSize.fontSize,
    );
    final TextStyle linkStyle = TextStyle(
      fontSize: prefState.fontSize.fontSize,
      decoration: TextDecoration.underline,
      color: Palette.orange,
    );
    if (item is Buildable) {
      return SelectableText.rich(
        buildTextSpan(
          (item as Buildable).elements,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtil.launch(link.url),
        ),
        onTap: onTap,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        contextMenuBuilder: (
          BuildContext context,
          EditableTextState editableTextState,
        ) =>
            contextMenuBuilder(
          context,
          editableTextState,
          item: item,
        ),
        semanticsLabel: item.text,
      );
    } else {
      return SelectableLinkify(
        text: item.text,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        style: style,
        linkStyle: linkStyle,
        onOpen: (LinkableElement link) => LinkUtil.launch(link.url),
        onTap: onTap,
        contextMenuBuilder: (
          BuildContext context,
          EditableTextState editableTextState,
        ) =>
            contextMenuBuilder(
          context,
          editableTextState,
          item: item,
        ),
        semanticsLabel: item.text,
      );
    }
  }
}
