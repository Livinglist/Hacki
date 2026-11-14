import 'package:hacki/models/models.dart';
import 'package:material_ui/material_ui.dart';

/// The shared layout for the live item menu and its settings preview.
class ItemMenuSheet extends StatelessWidget {
  const ItemMenuSheet({
    required this.enabledActions,
    required this.actions,
    required this.onCancel,
    super.key,
  });

  final List<ItemMenuAction> enabledActions;
  final Map<ItemMenuAction, Widget> actions;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final ItemMenuAction action in enabledActions)
            if (actions[action] case final Widget widget) widget,
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: onCancel,
          ),
        ],
      ),
    );
  }
}
