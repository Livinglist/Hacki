import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'history_state.dart';

/// Keeps the latest visited stories in most recently visited order.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({HistoryRepository? historyRepository})
    : _historyRepository =
          historyRepository ?? locator.get<HistoryRepository>(),
      super(const HistoryState(stories: <Story>[], status: Status.inProgress)) {
    _operations = _initialize();
  }

  final HistoryRepository _historyRepository;
  late Future<void> _operations;

  Future<void> _initialize() async {
    try {
      final List<Story> stories = await _historyRepository.loadVisitedStories();
      emit(
        HistoryState(stories: _recentStories(stories), status: Status.success),
      );
    } on Exception catch (error, stackTrace) {
      emit(state.copyWith(status: Status.failure));
      addError(error, stackTrace);
    }
  }

  /// Serializes visits with restoration and writes so rapid taps keep order.
  Future<void> recordStory(Story story) {
    if (isClosed || story.id <= 0 || story.dead || story.deleted) {
      return Future<void>.value();
    }

    return _operations = _operations.then((_) async {
      final List<Story> stories = _recentStories(<Story>[
        story,
        ...state.stories,
      ]);
      emit(HistoryState(stories: stories, status: Status.success));
      try {
        await _historyRepository.saveVisitedStories(stories);
      } on Exception catch (error, stackTrace) {
        emit(state.copyWith(status: Status.failure));
        addError(error, stackTrace);
      }
    });
  }

  List<Story> _recentStories(List<Story> stories) {
    final Set<int> ids = <int>{};
    return List<Story>.unmodifiable(
      stories
          .where((Story story) => ids.add(story.id))
          .take(HistoryRepository.maxVisitedStories),
    );
  }

  @override
  Future<void> close() async {
    await _operations;
    await super.close();
  }
}
