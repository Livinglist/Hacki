import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
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
        final bool swapped = preferenceState.areSlidePanesSwapped;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: Dimens.pt80,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: Dimens.pt36,
                    left: Dimens.zero,
                    right: Dimens.zero,
                    child: Row(
                      children: <Widget>[
                        SizedBoxes.pt16,
                        _SlideActionMenu(
                          current: preferenceState.leadingAction,
                          onChanged: (SlideAction action) {
                            context.read<PreferenceCubit>().update(
                              LeadingActionPreference(val: action.index),
                            );
                          },
                        ),
                        SizedBoxes.pt16,
                        _SlideActionMenu(
                          current: preferenceState.secondaryAction,
                          onChanged: (SlideAction action) {
                            context.read<PreferenceCubit>().update(
                              SecondaryActionPreference(val: action.index),
                            );
                          },
                        ),
                        SizedBoxes.pt16,
                        const Icon(Icons.more_horiz),
                        SizedBoxes.pt16,
                        const Spacer(),
                        _SlideActionMenu(
                          current: preferenceState.trailingAction,
                          onChanged: (SlideAction action) {
                            context.read<PreferenceCubit>().update(
                              TrailingActionPreference(val: action.index),
                            );
                          },
                        ),
                        SizedBoxes.pt16,
                      ].reversedIf(condition: swapped),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: .center,
                    children: <Widget>[
                      SizedBoxes.pt16,
                      const Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[Text('Leading slide action')],
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Swap leading and trailing panes',
                          onPressed: () {
                            HapticFeedbackUtils.selection();
                            context.read<PreferenceCubit>().update(
                              SwappedSlidePanesPreference(val: !swapped),
                            );
                          },
                        ),
                      ),
                      const Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[Text('Trailing slide action')],
                      ),
                      SizedBoxes.pt16,
                    ],
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

class _SlideActionMenu extends StatelessWidget {
  const _SlideActionMenu({required this.current, required this.onChanged});

  final SlideAction current;
  final ValueChanged<SlideAction> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SlideAction>(
      key: ValueKey<SlideAction>(current),
      initialValue: current,
      onSelected: (SlideAction action) {
        HapticFeedbackUtils.selection();
        onChanged(action);
      },
      itemBuilder: (BuildContext context) => SlideAction.values
          .map(
            (SlideAction val) => PopupMenuItem<SlideAction>(
              value: val,
              child: Row(
                children: <Widget>[
                  Icon(val.icon),
                  SizedBoxes.pt12,
                  Text(val.description),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.pt12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(current.icon),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
