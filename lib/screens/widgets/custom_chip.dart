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
      shape: const StadiumBorder(
        side: BorderSide(color: Palette.orange),
      ),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Palette.orange,
    );
  }
}
