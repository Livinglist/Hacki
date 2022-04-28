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
    required this.favStories,
    required this.status,
    required this.currentPage,
  });

  FavState.init()
      : favIds = <int>[],
        favStories = <Story>[],
        status = FavStatus.init,
        currentPage = 0;

  final List<int> favIds;
  final List<Story> favStories;
  final FavStatus status;
  final int currentPage;

  FavState copyWith({
    List<int>? favIds,
    List<Story>? favStories,
    FavStatus? status,
    int? currentPage,
  }) {
    return FavState(
      favIds: favIds ?? this.favIds,
      favStories: favStories ?? this.favStories,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        favIds,
        favStories,
        status,
        currentPage,
      ];
}
