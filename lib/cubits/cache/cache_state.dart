part of 'cache_cubit.dart';

class CacheState extends Equatable {
  const CacheState({required this.storiesReadStatus});

  CacheState.init() : storiesReadStatus = <int, bool>{};

  final Map<int, bool> storiesReadStatus;

  CacheState copyWith({required List<int> ids}) {
    return CacheState(
      storiesReadStatus: <int, bool>{
        ...storiesReadStatus,
        ...Map<int, bool>.fromEntries(
          ids.map((int e) => MapEntry<int, bool>(e, true)),
        )
      },
    );
  }

  CacheState copyWithStoryMarkedAsRead({required int id}) {
    return CacheState(
      storiesReadStatus: <int, bool>{...storiesReadStatus, id: true},
    );
  }

  CacheState copyWithStoryMarkedAsUnread({required int id}) {
    return CacheState(
      storiesReadStatus: <int, bool>{...storiesReadStatus, id: false},
    );
  }

  @override
  List<Object?> get props => <Object?>[storiesReadStatus];
}
