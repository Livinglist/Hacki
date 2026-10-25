import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class SlideActionSettings extends StatelessWidget {
  const SlideActionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (BuildContext context, PreferenceState preferenceState) {
        return OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowSpacing: Dimens.pt12,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: Dimens.pt16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Leading slide action'),
                  DropdownMenu<SlideAction>(
                    key: ValueKey<SlideAction>(preferenceState.leadingAction),
                    initialSelection: preferenceState.leadingAction,
                    dropdownMenuEntries: SlideAction.values
                        .map(
                          (SlideAction val) => DropdownMenuEntry<SlideAction>(
                            value: val,
                            label: val.description,
                          ),
                        )
                        .toList(),
                    onSelected: (SlideAction? action) {
                      if (action != null) {
                        HapticFeedbackUtils.selection();
                        context.read<PreferenceCubit>().update(
                          LeadingActionPreference(val: action.index),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Swap leading and trailing actions',
              onPressed: () {
                HapticFeedbackUtils.selection();
                final SlideAction leading = preferenceState.leadingAction;
                final SlideAction trailing = preferenceState.trailingAction;
                context.read<PreferenceCubit>()
                  ..update(LeadingActionPreference(val: trailing.index))
                  ..update(TrailingActionPreference(val: leading.index));
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.pt16,
                right: Dimens.pt16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Trailing slide action'),
                  DropdownMenu<SlideAction>(
                    key: ValueKey<SlideAction>(preferenceState.trailingAction),
                    initialSelection: preferenceState.trailingAction,
                    dropdownMenuEntries: SlideAction.values
                        .map(
                          (SlideAction val) => DropdownMenuEntry<SlideAction>(
                            value: val,
                            label: val.description,
                          ),
                        )
                        .toList(),
                    onSelected: (SlideAction? action) {
                      if (action != null) {
                        HapticFeedbackUtils.selection();
                        context.read<PreferenceCubit>().update(
                          TrailingActionPreference(val: action.index),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
