import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';

class TabBarSettings extends StatefulWidget {
  const TabBarSettings({super.key});

  @override
  State<TabBarSettings> createState() => _TabBarSettingsState();
}

class _TabBarSettingsState extends State<TabBarSettings> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabCubit, TabState>(
      builder: (BuildContext context, TabState state) {
        return ReorderableListView(
          onReorder: context.read<TabCubit>().update,
          children: <Widget>[
            for (final StoryType tab in state.tabs!)
              ListTile(
                key: ValueKey<StoryType>(tab),
                title: Text(tab.label),
              )
          ],
        );
      },
    );
  }
}
