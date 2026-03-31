import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/models/models.dart'
    show CommentsNumberFilter, NumericCondition;
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class NumberOfCommentsFilterChip extends StatelessWidget {
  const NumberOfCommentsFilterChip({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final CommentsNumberFilter? filter;
  final ValueChanged<CommentsNumberFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (_) async {
        final CommentsNumberFilter? filter = await onChipTapped(context);
        onChanged(filter);
      },
      selected: filter != null,
      label: filter == null
          ? 'num_cmt'
          : '${filter!.condition.operator} ${filter!.commentsNumber} comments',
    );
  }

  Future<CommentsNumberFilter?> onChipTapped(BuildContext context) async {
    final CommentsNumberFilter? updatedFilter =
        await showDialog<CommentsNumberFilter?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _NumberOfCommentsDialog(
          filter: filter,
        );
      },
    );
    return updatedFilter;
  }
}

class _NumberOfCommentsDialog extends StatefulWidget {
  const _NumberOfCommentsDialog({required this.filter});

  final CommentsNumberFilter? filter;

  @override
  State<_NumberOfCommentsDialog> createState() =>
      _NumberOfCommentsDialogState();
}

class _NumberOfCommentsDialogState extends State<_NumberOfCommentsDialog> {
  final TextEditingController _numberController = TextEditingController();
  NumericCondition _selectedCondition = NumericCondition.defaultValue;

  @override
  void initState() {
    super.initState();

    _selectedCondition =
        widget.filter?.condition ?? NumericCondition.defaultValue;
    if (widget.filter?.commentsNumber != null) {
      _numberController.text = widget.filter!.commentsNumber.toString();
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
            controller: _numberController,
            cursorColor: Theme.of(context).colorScheme.primary,
            keyboardType: TextInputType.number,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Number of comments',
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
                  final int? commentsNumber =
                      int.tryParse(_numberController.text.trim());
                  if (commentsNumber == null) return;
                  final CommentsNumberFilter filter = CommentsNumberFilter(
                    commentsNumber: commentsNumber,
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
