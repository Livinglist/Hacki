part of 'cache_cubit.dart';

class CacheState extends Equatable {
  const CacheState({required this.storiesReadStatus});

  CacheState.init() : storiesReadStatus = {};

  final Map<int, bool> storiesReadStatus;

  CacheState copyWith({required List<int> ids}) {
    return CacheState(
      storiesReadStatus: {
        ...storiesReadStatus,
        ...Map<int, bool>.fromEntries(
            ids.map((e) => MapEntry<int, bool>(e, true)))
      },
    );
  }

  CacheState copyWithStoryMarkedAsRead({required int id}) {
    return CacheState(storiesReadStatus: {...storiesReadStatus, id: true});
  }

  CacheState copyWithStoryMarkedAsUnread({required int id}) {
    return CacheState(storiesReadStatus: {...storiesReadStatus, id: false});
  }

  @override
  List<Object?> get props => [storiesReadStatus];
}
