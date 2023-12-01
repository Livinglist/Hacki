import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';

class ItemText extends StatelessWidget {
  const ItemText({
    required this.item,
    required this.textScaler,
    required this.selectable,
    super.key,
    this.onTap,
  });

  final Item item;
  final TextScaler textScaler;
  final bool selectable;

  /// Reserved for collapsing a comment tile when
  /// [CollapseModePreference] is enabled;
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
      color: Theme.of(context).colorScheme.primary,
    );

    void onSelectionChanged(
      TextSelection selection,
      SelectionChangedCause? cause,
    ) {
      if (cause == SelectionChangedCause.longPress &&
          selection.baseOffset != selection.extentOffset) {
        context.tryRead<CollapseCubit>()?.lock();
      }
    }

    if (selectable && item is Buildable) {
      return SelectableText.rich(
        buildTextSpan(
          (item as Buildable).elements,
          primaryColor: context.read<PreferenceCubit>().state.appColor,
          style: style,
          linkStyle: linkStyle,
          onOpen: (LinkableElement link) => LinkUtil.launch(
            link.url,
            context,
          ),
        ),
        onTap: onTap,
        textScaler: textScaler,
        onSelectionChanged: onSelectionChanged,
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
      if (item is Buildable) {
        return InkWell(
          child: Text.rich(
            buildTextSpan(
              (item as Buildable).elements,
              primaryColor: context.read<PreferenceCubit>().state.appColor,
              style: style,
              linkStyle: linkStyle,
              onOpen: (LinkableElement link) => LinkUtil.launch(
                link.url,
                context,
              ),
            ),
            textScaler: textScaler,
            semanticsLabel: item.text,
          ),
        );
      } else {
        return InkWell(
          child: Linkify(
            text: item.text,
            textScaler: textScaler,
            style: style,
            linkStyle: linkStyle,
            onOpen: (LinkableElement link) => LinkUtil.launch(
              link.url,
              context,
            ),
          ),
        );
      }
    }
  }
}
