part of 'poll_cubit.dart';

enum PollStatus {
  initial,
  loading,
  loaded,
  failure,
}

class PollState extends Equatable {
  const PollState({
    required this.totalVotes,
    required this.selections,
    required this.pollOptions,
    required this.status,
  });

  PollState.init()
      : totalVotes = 0,
        selections = <int>{},
        pollOptions = <PollOption>[],
        status = PollStatus.initial;

  final int totalVotes;
  final Set<int> selections;
  final List<PollOption> pollOptions;
  final PollStatus status;

  PollState copyWith({
    int? totalVotes,
    Set<int>? selections,
    List<PollOption>? pollOptions,
    PollStatus? status,
  }) {
    return PollState(
      totalVotes: totalVotes ?? this.totalVotes,
      selections: selections ?? this.selections,
      pollOptions: pollOptions ?? this.pollOptions,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        totalVotes,
        selections,
        pollOptions,
        status,
      ];
}
