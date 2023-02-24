import 'package:flutter/material.dart';
import 'package:hacki/models/search_params.dart';
import 'package:hacki/screens/widgets/widgets.dart';

/// [ItemFilterChip] is used for [StoryFilter], [PollFilter]
/// and [CommentFilter].
class ItemFilterChip extends StatelessWidget {
  const ItemFilterChip({
    super.key,
    required this.label,
    required this.filter,
    required this.onSelected,
  });

  final String label;
  final TagFilter? filter;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: onSelected,
      selected: filter != null,
      label: label,
    );
  }
}
