import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/settings/widgets/item_menu_preview.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class ItemMenuSettingsScreen extends StatelessWidget {
  const ItemMenuSettingsScreen({super.key});

  void _showPreview(BuildContext context) {
    HapticFeedbackUtils.selection();
    final PreferenceCubit preferenceCubit = context.read<PreferenceCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider<PreferenceCubit>.value(
        value: preferenceCubit,
        child: const SafeArea(child: ItemMenuPreview()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        title: const Text('Item Actions'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset item actions',
            icon: const Icon(Icons.restore),
            onPressed: () {
              HapticFeedbackUtils.selection();
              context.read<PreferenceCubit>().resetItemMenuActions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<PreferenceCubit, PreferenceState>(
          builder: (BuildContext context, PreferenceState state) {
            final List<ItemMenuAction> actions = state.itemMenuActions;
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              footer: Padding(
                padding: const EdgeInsets.all(Dimens.pt16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => _showPreview(context),
                    child: const Text('Preview'),
                  ),
                ),
              ),
              itemCount: actions.length,
              onReorderStart: (_) => HapticFeedbackUtils.light(),
              onReorderItem: (int oldIndex, int newIndex) {
                final List<ItemMenuAction> reordered = List<ItemMenuAction>.of(
                  actions,
                );
                reordered.insert(newIndex, reordered.removeAt(oldIndex));
                context.read<PreferenceCubit>().updateItemMenuActions(
                  reordered,
                );
              },
              itemBuilder: (BuildContext context, int index) {
                final ItemMenuAction action = actions[index];
                return ListTile(
                  key: ValueKey<ItemMenuAction>(action),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimens.pt16,
                  ),
                  leading: Icon(action.icon),
                  title: Text(action.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Semantics(
                        label: action.description,
                        child: Switch(
                          activeThumbColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          value: state.enabledItemMenuActions.contains(action),
                          onChanged: (bool enabled) {
                            context
                                .read<PreferenceCubit>()
                                .setItemMenuActionEnabled(
                                  action,
                                  enabled: enabled,
                                );
                          },
                        ),
                      ),
                      ReorderableDelayedDragStartListener(
                        index: index,
                        child: Semantics(
                          label: 'Reorder ${action.description}',
                          child: Container(
                            width: Dimens.pt48,
                            height: Dimens.pt48,
                            color: Palette.transparent,
                            alignment: AlignmentDirectional.centerEnd,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
