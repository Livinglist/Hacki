part of 'time_machine_cubit.dart';

class TimeMachineState extends Equatable {
  const TimeMachineState({required this.ancestors});

  TimeMachineState.init() : ancestors = <Comment>[];

  final List<Comment> ancestors;

  TimeMachineState copyWith({
    List<Comment>? ancestors,
  }) {
    return TimeMachineState(ancestors: ancestors ?? this.ancestors);
  }

  @override
  List<Object?> get props => <Object?>[ancestors];
}
