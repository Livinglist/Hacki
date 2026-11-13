import 'package:equatable/equatable.dart';

/// A position in a thread that the user can navigate back or forward to.
class NavigationAnchor extends Equatable {
  const NavigationAnchor({required this.itemId, required this.alignment});

  /// The id of the comment at this position, or the id of the thread's root
  /// item when the position is the header of the thread.
  final int itemId;

  /// Where the leading edge of the item sits in the viewport, as a fraction
  /// of the viewport's height.
  final double alignment;

  @override
  List<Object?> get props => <Object?>[itemId, alignment];
}
