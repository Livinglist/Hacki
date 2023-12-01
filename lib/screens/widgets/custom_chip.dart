import 'package:flutter/material.dart';
import 'package:hacki/styles/styles.dart';

class CustomChip extends StatelessWidget {
  CustomChip({
    required this.selected,
    required this.label,
    required this.onSelected,
    Key? key,
  }) : super(key: key ?? Key(label));

  final bool selected;
  final String label;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      shadowColor: Palette.transparent,
      selectedShadowColor: Palette.transparent,
      backgroundColor: Palette.transparent,
      side: selected
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : BorderSide(color: Theme.of(context).colorScheme.onSurface),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).colorScheme.onPrimary : null,
      ),
      checkmarkColor: selected ? Theme.of(context).colorScheme.onPrimary : null,
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
    );
  }
}
