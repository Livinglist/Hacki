part of 'submitted_cubit.dart';

class SubmittedState extends Equatable {
  const SubmittedState({
    required this.submittedIds,
    required this.submittedItems,
    required this.status,
    required this.currentPage,
  });

  SubmittedState.init()
    : submittedIds = <int>[],
      submittedItems = <Item>[],
      status = Status.idle,
      currentPage = 0;

  final List<int> submittedIds;
  final List<Item> submittedItems;
  final Status status;
  final int currentPage;

  SubmittedState copyWith({
    List<int>? submittedIds,
    List<Item>? submittedItems,
    Status? status,
    int? currentPage,
  }) {
    return SubmittedState(
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
