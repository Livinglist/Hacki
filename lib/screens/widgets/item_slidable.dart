import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps [child] with the slidable panes configured in the slide action
/// settings: a leading pane holding the leading, secondary, edit and more
/// actions, and a trailing pane holding the single trailing action.
class ItemSlidable extends StatelessWidget {
  const ItemSlidable({
    required this.item,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
    super.key,
    this.enabled = true,
    this.unavailableActions = const <SlideAction>{},
    this.onLeadingActionTapped,
    this.onSecondaryActionTapped,
    this.onTrailingActionTapped,
    this.onEditTapped,
    this.onMoreTapped,
  });

  final Item item;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;
  final bool enabled;

  /// Actions that make no sense for [item] and should not be offered.
  final Set<SlideAction> unavailableActions;

  final VoidCallback? onLeadingActionTapped;
  final VoidCallback? onSecondaryActionTapped;
  final VoidCallback? onTrailingActionTapped;
  final VoidCallback? onEditTapped;
  final void Function(Rect?)? onMoreTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.leadingAction != current.leadingAction ||
          previous.secondaryAction != current.secondaryAction ||
          previous.trailingAction != current.trailingAction ||
          previous.areSlidePanesSwapped != current.areSlidePanesSwapped,
      builder: (BuildContext context, PreferenceState prefState) {
        final bool isOwnItem =
            context.read<AuthBloc>().state.user.id == item.by;
        final bool arePanesSwapped = prefState.areSlidePanesSwapped;

        bool isHidden(SlideAction action) =>
            unavailableActions.contains(action) ||
            (isOwnItem &&
                (action == SlideAction.upvote ||
                    action == SlideAction.downvote));

        /// When the panes are swapped, this pane's children are reversed
        /// so that the leading action is still revealed first with a small
        /// swipe and the more action still needs the fullest swipe, even
        /// though this pane now renders on the opposite side.
        final ActionPane? leadingGroupPane = enabled
            ? ActionPane(
                motion: const BehindMotion(),
                dismissible: DismissiblePane(
                  closeOnCancel: true,
                  confirmDismiss: () async {
                    if (!unavailableActions.contains(prefState.leadingAction)) {
                      onLeadingActionTapped?.call();
                    }
                    return false;
                  },
                  onDismissed: () {},
                ),
                children: <Widget>[
                  if (onLeadingActionTapped != null &&
                      !isHidden(prefState.leadingAction))
                    CustomSlidableAction(
                      onPressed: (_) => onLeadingActionTapped?.call(),
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      child: Icon(
                        prefState.leadingAction.icon,
                        size: Dimens.pt24,
                      ),
                    ),
                  if (onSecondaryActionTapped != null &&
                      !isHidden(prefState.secondaryAction))
                    CustomSlidableAction(
                      onPressed: (_) => onSecondaryActionTapped?.call(),
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      child: Icon(
                        prefState.secondaryAction.icon,
                        size: Dimens.pt24,
                      ),
                    ),
                  if (onEditTapped != null && isOwnItem)
                    CustomSlidableAction(
                      onPressed: (_) => onEditTapped?.call(),
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      child: const Icon(Icons.edit, size: Dimens.pt24),
                    ),
                  CustomSlidableAction(
                    onPressed: (BuildContext context) =>
                        onMoreTapped?.call(context.rect),
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    child: const Icon(Icons.more_horiz, size: Dimens.pt24),
                  ),
                ].reversedIf(condition: arePanesSwapped),
              )
            : null;

        /// The low dismiss threshold belongs to this pane, not to a screen
        /// side, so it keeps applying after the panes are swapped.
        final ActionPane? trailingGroupPane =
            enabled &&
                onTrailingActionTapped != null &&
                !isHidden(prefState.trailingAction)
            ? ActionPane(
                motion: const BehindMotion(),
                dismissible: DismissiblePane(
                  closeOnCancel: true,
                  dismissThreshold: 0.01,
                  confirmDismiss: () async {
                    onTrailingActionTapped?.call();
                    return false;
                  },
                  onDismissed: () {},
                ),
                children: <Widget>[
                  CustomSlidableAction(
                    onPressed: (_) => onTrailingActionTapped?.call(),
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    child: Icon(
                      prefState.trailingAction.icon,
                      size: Dimens.pt24,
                    ),
                  ),
                ],
              )
            : null;

        return Slidable(
          key: ValueKey<String>('item_slidable_${item.id}'),
          startActionPane: arePanesSwapped
              ? trailingGroupPane
              : leadingGroupPane,
          endActionPane: arePanesSwapped ? leadingGroupPane : trailingGroupPane,
          child: child,
        );
      },
    );
  }
}
