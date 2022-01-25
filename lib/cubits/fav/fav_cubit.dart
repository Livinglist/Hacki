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
    AuthRepository? authRepository,
    StorageRepository? storageRepository,
    StoriesRepository? storiesRepository,
  })  : _authBloc = authBloc,
        _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(FavState.init()) {
    init();
  }

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
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

  Future<void> addFav(int id) async {
    final username = _authBloc.state.username;

    await _storageRepository.addFav(username: username, id: id);

    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..add(id),
      ),
    );

    final story = await _storiesRepository.fetchStoryById(id);

    emit(state.copyWith(
        favStories: List<Story>.from(state.favStories)..insert(0, story)));

    if (_authBloc.state.isLoggedIn) {
      await _authRepository.favorite(id: id, favorite: true);
    }
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

    if (_authBloc.state.isLoggedIn) {
      _authRepository.favorite(id: id, favorite: false);
    }
  }

  void loadMore() {
    emit(state.copyWith(status: FavStatus.loading));
    final currentPage = state.currentPage;
    final len = state.favIds.length;
    emit(state.copyWith(currentPage: currentPage + 1));
    final lower = _pageSize * (currentPage + 1);
    var upper = _pageSize + lower;

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

  void _onStoryLoaded(Story story) {
    emit(state.copyWith(
        favStories: List<Story>.from(state.favStories)..add(story)));
  }
}
