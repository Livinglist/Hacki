part of 'fav_cubit.dart';

class FavState extends Equatable {
  const FavState({
    required this.favIds,
    required this.favItems,
    required this.status,
    required this.mergeStatus,
    required this.currentPage,
    required this.isDisplayingStories,
  });

  FavState.init()
      : favIds = <int>[],
        favItems = <Item>[],
        status = Status.idle,
        mergeStatus = Status.idle,
        currentPage = 0,
        isDisplayingStories = true;

  final List<int> favIds;
  final List<Item> favItems;
  final Status status;
  final Status mergeStatus;
  final int currentPage;
  final bool isDisplayingStories;

  FavState copyWith({
    List<int>? favIds,
    List<Item>? favItems,
    Status? status,
    Status? mergeStatus,
    int? currentPage,
    bool? isDisplayingStories,
  }) {
    return FavState(
      favIds: favIds ?? this.favIds,
      favItems: favItems ?? this.favItems,
      status: status ?? this.status,
      mergeStatus: mergeStatus ?? this.mergeStatus,
      currentPage: currentPage ?? this.currentPage,
      isDisplayingStories: isDisplayingStories ?? this.isDisplayingStories,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        mergeStatus,
        currentPage,
        favIds,
        favItems,
        isDisplayingStories,
      ];
}
