import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  CustomChip({
    Key? key,
    required this.selected,
    required this.label,
    required this.onSelected,
  }) : super(key: key ?? Key(label));

  final bool selected;
  final String label;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      shape: const StadiumBorder(
        side: BorderSide(color: Colors.orange),
      ),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.orange,
    );
  }
}
