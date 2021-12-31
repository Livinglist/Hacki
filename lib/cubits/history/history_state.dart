part of 'history_cubit.dart';

enum HistoryStatus {
  init,
  loading,
  loaded,
  failure,
}

class HistoryState extends Equatable {
  const HistoryState({
    required this.submittedIds,
    required this.submittedItems,
    required this.status,
    required this.currentPage,
  });

  HistoryState.init()
      : submittedIds = [],
        submittedItems = [],
        status = HistoryStatus.init,
        currentPage = 0;

  final List<int> submittedIds;
  final List<Item> submittedItems;
  final HistoryStatus status;
  final int currentPage;

  HistoryState copyWith({
    List<int>? submittedIds,
    List<Item>? submittedItems,
    HistoryStatus? status,
    int? currentPage,
  }) {
    return HistoryState(
      submittedIds: submittedIds ?? this.submittedIds,
      submittedItems: submittedItems ?? this.submittedItems,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        submittedIds,
        submittedItems,
        status,
        currentPage,
      ];
}
