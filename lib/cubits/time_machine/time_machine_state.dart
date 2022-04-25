part of 'time_machine_cubit.dart';

class TimeMachineState extends Equatable {
  const TimeMachineState({required this.parents});

  TimeMachineState.init() : parents = [];

  final List<Comment> parents;

  TimeMachineState copyWith({
    List<Comment>? parents,
  }) {
    return TimeMachineState(parents: parents ?? this.parents);
  }

  @override
  List<Object?> get props => [parents];
}
