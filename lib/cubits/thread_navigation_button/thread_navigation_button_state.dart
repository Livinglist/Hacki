part of 'thread_navigation_button_cubit.dart';

const Offset defaultOffset = Offset(16, 180);

class ThreadNavigationButtonState extends Equatable {
  const ThreadNavigationButtonState({required this.dx, required this.dy});

  ThreadNavigationButtonState.init()
    : dx = defaultOffset.dx,
      dy = defaultOffset.dy;

  final double dx;
  final double dy;

  ThreadNavigationButtonState copyWith({
    required double dx,
    required double dy,
  }) {
    return ThreadNavigationButtonState(dx: dx, dy: dy);
  }

  @override
  List<Object?> get props => <Object?>[dx, dy];
}
