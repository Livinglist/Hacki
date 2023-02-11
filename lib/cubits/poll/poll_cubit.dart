import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'poll_state.dart';

class PollCubit extends Cubit<PollState> {
  PollCubit({
    required Story story,
    StoriesRepository? storiesRepository,
  })  : _story = story,
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(PollState.init());

  final StoriesRepository _storiesRepository;
  final Story _story;

  Future<void> init({
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(PollState.init());
    }

    emit(state.copyWith(status: PollStatus.loading));

    List<int> pollOptionsIds = _story.parts;

    if (pollOptionsIds.isEmpty || refresh) {
      final Story? updatedStory =
          await _storiesRepository.fetchStory(id: _story.id);

      if (updatedStory != null) {
        pollOptionsIds = updatedStory.parts;
      }
    }

    // If pollOptionsIds is still empty, exit loading state.
    if (pollOptionsIds.isEmpty) {
      emit(state.copyWith(status: PollStatus.loaded));
      return;
    }

    if (pollOptionsIds.isNotEmpty) {
      final List<PollOption> pollOptions = (await _storiesRepository
              .fetchPollOptionsStream(ids: pollOptionsIds)
              .toSet())
          .toList();

      final int totalVotes = pollOptions
          .map((PollOption e) => e.score)
          .reduce((int value, int element) => value + element);

      for (final PollOption pollOption in pollOptions) {
        final double ratio = _calculateRatio(totalVotes, pollOption.score);
        final PollOption updatedOption = pollOption.copyWith(ratio: ratio);

        emit(
          state.copyWith(
            totalVotes: totalVotes,
            pollOptions: <PollOption>[...state.pollOptions, updatedOption]
              ..sort(
                (PollOption left, PollOption right) =>
                    right.score.compareTo(left.score),
              ),
          ),
        );
      }

      emit(state.copyWith(status: PollStatus.loaded));
    }
  }

  void refresh() => init(refresh: true);

  double _calculateRatio(int totalVotes, int votes) =>
      totalVotes == 0 ? 0 : votes / totalVotes;
}
