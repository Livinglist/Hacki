part of 'fav_cubit.dart';

class FavState extends Equatable {
  const FavState({
    required this.favIds,
    required this.favItems,
    required this.status,
    required this.mergeStatus,
    required this.currentPage,
  });

  FavState.init()
      : favIds = <int>[],
        favItems = <Item>[],
        status = Status.idle,
        mergeStatus = Status.idle,
        currentPage = 0;

  final List<int> favIds;
  final List<Item> favItems;
  final Status status;
  final Status mergeStatus;
  final int currentPage;

  FavState copyWith({
    List<int>? favIds,
    List<Item>? favItems,
    Status? status,
    Status? mergeStatus,
    int? currentPage,
  }) {
    return FavState(
      favIds: favIds ?? this.favIds,
      favItems: favItems ?? this.favItems,
      status: status ?? this.status,
      mergeStatus: mergeStatus ?? this.mergeStatus,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        mergeStatus,
        currentPage,
        favIds,
        favItems,
      ];
}
