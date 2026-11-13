part of 'thread_navigation_button_cubit.dart';

const Offset defaultOffset = Offset(16, 120);

/// To the left of the skip buttons.
const Offset defaultHistoryOffset = Offset(84, 120);

class ThreadNavigationButtonState extends Equatable {
  const ThreadNavigationButtonState({
    required this.dx,
    required this.dy,
    required this.historyDx,
    required this.historyDy,
  });

  ThreadNavigationButtonState.init()
    : dx = defaultOffset.dx,
      dy = defaultOffset.dy,
      historyDx = defaultHistoryOffset.dx,
      historyDy = defaultHistoryOffset.dy;

  /// The distance of the skip buttons from the right and bottom edges.
  final double dx;
  final double dy;

  /// The distance of the back and forward buttons from the right and bottom
  /// edges, used when they are not combined with the skip buttons.
  final double historyDx;
  final double historyDy;

  ThreadNavigationButtonState copyWith({
    double? dx,
    double? dy,
    double? historyDx,
    double? historyDy,
  }) {
    return ThreadNavigationButtonState(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      historyDx: historyDx ?? this.historyDx,
      historyDy: historyDy ?? this.historyDy,
    );
  }

  @override
  List<Object?> get props => <Object?>[dx, dy, historyDx, historyDy];
}
