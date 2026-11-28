part of 'history_cubit.dart';

class HistoryState extends Equatable {
  const HistoryState({required this.stories, required this.status});

  final List<Story> stories;
  final Status status;

  HistoryState copyWith({List<Story>? stories, Status? status}) {
    return HistoryState(
      stories: stories ?? this.stories,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[stories, status];
}
