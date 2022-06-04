import 'package:flutter/material.dart';
import 'package:hacki/models/search_filters.dart';
import 'package:hacki/screens/widgets/widgets.dart';

class PostedByFilterChip extends StatelessWidget {
  const PostedByFilterChip({
    Key? key,
    required this.filter,
  }) : super(key: key);

  final PostedByFilter? filter;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (bool value) {},
      selected: filter != null,
      label: '''posted by ${filter?.author ?? ''}''',
    );
  }
}
