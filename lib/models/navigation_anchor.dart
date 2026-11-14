import 'package:equatable/equatable.dart';
import 'package:hacki/models/item/comment.dart';

/// A position in a thread that the user can navigate back or forward to.
class NavigationAnchor extends Equatable {
  const NavigationAnchor({required this.itemId, required this.alignment})
    : targetComment = null;

  /// Keeps the selected comment as the destination of a programmatic jump.
  NavigationAnchor.forComment(Comment comment, {required this.alignment})
    : itemId = comment.id,
      targetComment = comment;

  /// The id of the comment at this position, or the id of the thread's root
  /// item when the position is the header of the thread.
  final int itemId;

  /// The comment explicitly selected by a jump. Reading positions captured
  /// from manual scrolling have no target comment.
  final Comment? targetComment;

  /// Where the leading edge of the item sits in the viewport, as a fraction
  /// of the viewport's height.
  final double alignment;

  /// Treat tiny viewport differences as layout drift.
  static const double alignmentTolerance = 0.01;

  bool isSamePosition(NavigationAnchor other) =>
      itemId == other.itemId &&
      (alignment - other.alignment).abs() <= alignmentTolerance;

  @override
  List<Object?> get props => <Object?>[itemId, alignment, targetComment?.id];
}
