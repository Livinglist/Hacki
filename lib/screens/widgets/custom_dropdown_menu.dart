import 'package:flutter/material.dart';
import 'package:hacki/styles/styles.dart';

class CustomDropdownMenu<T> extends StatelessWidget {
  const CustomDropdownMenu({
    required this.menuChildren,
    required this.onSelected,
    required this.selected,
    super.key,
  });

  final List<T> menuChildren;
  final void Function(T) onSelected;
  final T selected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: menuChildren
          .map(
            (T val) => MenuItemButton(
              onPressed: () => onSelected(val),
              child: Text(
                val.toString(),
                style: Theme.of(context).textTheme.labelLarge,
                textScaler: MediaQuery.of(context).clampedTextScaler,
              ),
            ),
          )
          .toList(),
      builder: (BuildContext context, MenuController controller, _) {
        return InkWell(
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Dimens.pt8,
              horizontal: Dimens.pt4,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  selected.toString(),
                  style: Theme.of(context).textTheme.labelLarge,
                  textScaler: MediaQuery.of(context).clampedTextScaler,
                ),
                Icon(
                  controller.isOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
              ],
            ),
          ),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}
