part of 'fav_cubit.dart';

enum FavStatus {
  init,
  loading,
  loaded,
  failure,
}

class FavState extends Equatable {
  const FavState({
    required this.favIds,
    required this.favItems,
    required this.status,
    required this.currentPage,
  });

  FavState.init()
      : favIds = <int>[],
        favItems = <Item>[],
        status = FavStatus.init,
        currentPage = 0;

  final List<int> favIds;
  final List<Item> favItems;
  final FavStatus status;
  final int currentPage;

  FavState copyWith({
    List<int>? favIds,
    List<Item>? favItems,
    FavStatus? status,
    int? currentPage,
  }) {
    return FavState(
      favIds: favIds ?? this.favIds,
      favItems: favItems ?? this.favItems,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        currentPage,
        favIds,
        favItems,
      ];
}
