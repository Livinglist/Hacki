part of 'history_cubit.dart';

class HistoryState extends Equatable {
  const HistoryState({
    required this.submittedIds,
    required this.submittedItems,
    required this.status,
    required this.currentPage,
  });

  HistoryState.init()
      : submittedIds = <int>[],
        submittedItems = <Item>[],
        status = Status.idle,
        currentPage = 0;

  final List<int> submittedIds;
  final List<Item> submittedItems;
  final Status status;
  final int currentPage;

  HistoryState copyWith({
    List<int>? submittedIds,
    List<Item>? submittedItems,
    Status? status,
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
  List<Object?> get props => <Object?>[
        status,
        currentPage,
        submittedIds,
        submittedItems,
      ];
}
