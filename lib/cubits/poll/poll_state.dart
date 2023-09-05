part of 'poll_cubit.dart';

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
        status = Status.idle;

  final int totalVotes;
  final Set<int> selections;
  final List<PollOption> pollOptions;
  final Status status;

  PollState copyWith({
    int? totalVotes,
    Set<int>? selections,
    List<PollOption>? pollOptions,
    Status? status,
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
