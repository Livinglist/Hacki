import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'fav_state.dart';

class FavCubit extends Cubit<FavState> {
  FavCubit({
    required AuthBloc authBloc,
    StorageRepository? storageRepository,
    StoriesRepository? storiesRepository,
  })  : _authBloc = authBloc,
        _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(FavState.init()) {
    init();
  }

  final AuthBloc _authBloc;
  final StorageRepository _storageRepository;
  final StoriesRepository _storiesRepository;
  static const _pageSize = 20;
  String? _username;

  Future<void> init() async {
    _authBloc.stream.listen((authState) {
      if (authState.username != _username) {
        _storageRepository.favList(of: authState.username).then((favIds) {
          emit(state.copyWith(
            favIds: favIds,
            favStories: [],
            currentPage: 0,
          ));
          _storiesRepository
              .fetchStoriesStream(
                  ids: favIds.sublist(0, _pageSize.clamp(0, favIds.length)))
              .listen(_onStoryLoaded)
              .onDone(() {
            emit(state.copyWith(
              status: FavStatus.loaded,
            ));
          });
        });

        _username = authState.username;
      }
    });
  }

  void addFav(int id) {
    final username = _authBloc.state.username;

    _storageRepository.addFav(username: username, id: id);
    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..add(id),
      ),
    );
  }

  void removeFav(int id) {
    final username = _authBloc.state.username;

    _storageRepository.removeFav(username: username, id: id);
    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..remove(id),
        favStories: List<Story>.from(state.favStories)
          ..removeWhere((e) => e.id == id),
      ),
    );
  }

  void loadMore() {
    emit(state.copyWith(status: FavStatus.loading));
    final currentPage = state.currentPage;
    final len = state.favIds.length;
    emit(state.copyWith(currentPage: currentPage + 1));
    final lower = _pageSize * (currentPage + 1);
    var upper = _pageSize + _pageSize * (currentPage + 1);

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      _storiesRepository
          .fetchStoriesStream(
              ids: state.favIds.sublist(
            lower,
            upper,
          ))
          .listen(_onStoryLoaded)
          .onDone(() {
        emit(state.copyWith(status: FavStatus.loaded));
      });
    } else {
      emit(state.copyWith(status: FavStatus.loaded));
    }
  }

  void refresh() {
    final username = _authBloc.state.username;
    emit(state.copyWith(
      status: FavStatus.loading,
      currentPage: 0,
      favStories: [],
      favIds: [],
    ));

    _storageRepository.favList(of: username).then((favIds) {
      emit(state.copyWith(favIds: favIds));
      _storiesRepository
          .fetchStoriesStream(
              ids: favIds.sublist(0, _pageSize.clamp(0, favIds.length)))
          .listen(_onStoryLoaded)
          .onDone(() {
        emit(state.copyWith(status: FavStatus.loaded));
      });
    });
  }

  void reset() {
    emit(state.copyWith(
      favIds: [],
      favStories: [],
      currentPage: 0,
    ));
  }

  void _onStoryLoaded(Story story) {
    emit(state.copyWith(
        favStories: List<Story>.from(state.favStories)..add(story)));
  }
}
