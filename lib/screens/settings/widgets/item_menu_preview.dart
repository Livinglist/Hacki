import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/item_menu_sheet.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the current menu with sample data and no live item actions.
class ItemMenuPreview extends StatelessWidget {
  const ItemMenuPreview({super.key});

  static const User _sampleUser = User(
    about: '',
    created: 1304640000,
    delay: 0,
    id: 'example_user',
    karma: 3520,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (BuildContext context, PreferenceState state) {
        return ItemMenuSheet(
          enabledActions: state.enabledItemMenuActions,
          actions: <ItemMenuAction, Widget>{
            for (final ItemMenuAction action in ItemMenuAction.values)
              action: action == ItemMenuAction.viewProfile
                  ? ListTile(
                      leading: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[Icon(Icons.account_circle)],
                      ),
                      title: Text(_sampleUser.id),
                      subtitle: Text(_sampleUser.description),
                    )
                  : ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.description),
                    ),
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
