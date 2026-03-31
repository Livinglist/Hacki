import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/models/models.dart' show NumericCondition, PointsFilter;
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class PointsFilterChip extends StatelessWidget {
  const PointsFilterChip({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final PointsFilter? filter;
  final ValueChanged<PointsFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (_) async {
        final PointsFilter? filter = await onChipTapped(context);
        onChanged(filter);
      },
      selected: filter != null,
      label: filter == null
          ? 'points'
          : '${filter!.condition.operator} ${filter!.points} points',
    );
  }

  Future<PointsFilter?> onChipTapped(BuildContext context) async {
    final PointsFilter? updatedFilter = await showDialog<PointsFilter?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _PointsDialog(
          filter: filter,
        );
      },
    );
    return updatedFilter;
  }
}

class _PointsDialog extends StatefulWidget {
  const _PointsDialog({required this.filter});

  final PointsFilter? filter;

  @override
  State<_PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<_PointsDialog> {
  final TextEditingController _pointsController = TextEditingController();
  NumericCondition _selectedCondition = NumericCondition.defaultValue;

  @override
  void initState() {
    super.initState();

    _selectedCondition =
        widget.filter?.condition ?? NumericCondition.defaultValue;
    if (widget.filter?.points != null) {
      _pointsController.text = widget.filter!.points.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt18,
          ),
          child: SegmentedButton<NumericCondition>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: <ButtonSegment<NumericCondition>>[
              for (final NumericCondition condition in NumericCondition.values)
                ButtonSegment<NumericCondition>(
                  value: condition,
                  label: Text(condition.operator),
                ),
            ],
            selected: <NumericCondition>{
              _selectedCondition,
            },
            onSelectionChanged: (Set<NumericCondition> val) {
              HapticFeedbackUtil.light();
              setState(() {
                _selectedCondition = val.single;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.pt18,
          ),
          child: TextField(
            controller: _pointsController,
            cursorColor: Theme.of(context).colorScheme.primary,
            keyboardType: TextInputType.number,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Points',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const SizedBox(
          height: Dimens.pt16,
        ),
        Padding(
          padding: const EdgeInsets.only(
            right: Dimens.pt12,
          ),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () => context.pop(widget.filter),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Remove',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final int? points =
                      int.tryParse(_pointsController.text.trim());
                  if (points == null) return;
                  final PointsFilter filter = PointsFilter(
                    points: points,
                    condition: _selectedCondition,
                  );
                  context.pop(filter);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
