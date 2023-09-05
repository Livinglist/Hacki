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
    PreferenceRepository? preferenceRepository,
    StoriesRepository? storiesRepository,
  })  : _authBloc = authBloc,
        _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(FavState.init()) {
    init();
  }

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;
  final StoriesRepository _storiesRepository;
  static const int _pageSize = 20;
  String? _username;

  Future<void> init() async {
    _authBloc.stream.listen((AuthState authState) {
      if (authState.username != _username) {
        _preferenceRepository
            .favList(of: authState.username)
            .then((List<int> favIds) {
          emit(
            state.copyWith(
              favIds: favIds,
              favItems: <Item>[],
              currentPage: 0,
            ),
          );
          _storiesRepository
              .fetchItemsStream(
                ids: favIds.sublist(0, _pageSize.clamp(0, favIds.length)),
              )
              .listen(_onItemLoaded)
              .onDone(() {
            emit(
              state.copyWith(
                status: Status.success,
              ),
            );
          });
        });

        _username = authState.username;
      }
    });
  }

  Future<void> addFav(int id) async {
    final String username = _authBloc.state.username;

    await _preferenceRepository.addFav(username: username, id: id);

    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..add(id),
      ),
    );

    final Item? item = await _storiesRepository.fetchItem(id: id);

    if (item == null) return;

    emit(
      state.copyWith(
        favItems: List<Item>.from(state.favItems)..insert(0, item),
      ),
    );

    if (_authBloc.state.isLoggedIn) {
      await _authRepository.favorite(id: id, favorite: true);
    }
  }

  void removeFav(int id) {
    final String username = _authBloc.state.username;

    _preferenceRepository.removeFav(username: username, id: id);

    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..remove(id),
        favItems: List<Item>.from(state.favItems)
          ..removeWhere((Item e) => e.id == id),
      ),
    );

    if (_authBloc.state.isLoggedIn) {
      _authRepository.favorite(id: id, favorite: false);
    }
  }

  void loadMore() {
    emit(state.copyWith(status: Status.inProgress));
    final int currentPage = state.currentPage;
    final int len = state.favIds.length;
    emit(state.copyWith(currentPage: currentPage + 1));
    final int lower = _pageSize * (currentPage + 1);
    int upper = _pageSize + lower;

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      _storiesRepository
          .fetchItemsStream(
            ids: state.favIds.sublist(
              lower,
              upper,
            ),
          )
          .listen(_onItemLoaded)
          .onDone(() {
        emit(state.copyWith(status: Status.success));
      });
    } else {
      emit(state.copyWith(status: Status.success));
    }
  }

  void refresh() {
    final String username = _authBloc.state.username;

    emit(
      state.copyWith(
        status: Status.inProgress,
        currentPage: 0,
        favItems: <Item>[],
        favIds: <int>[],
      ),
    );

    _preferenceRepository.favList(of: username).then((List<int> favIds) {
      emit(state.copyWith(favIds: favIds));
      _storiesRepository
          .fetchItemsStream(
            ids: favIds.sublist(0, _pageSize.clamp(0, favIds.length)),
          )
          .listen(_onItemLoaded)
          .onDone(() {
        emit(state.copyWith(status: Status.success));
      });
    });
  }

  void removeAll() {
    _preferenceRepository
      ..clearAllFavs(username: '')
      ..clearAllFavs(username: _authBloc.state.username);
    emit(FavState.init());
  }

  void _onItemLoaded(Item item) {
    emit(
      state.copyWith(
        favItems: List<Item>.from(state.favItems)..add(item),
      ),
    );
  }
}
