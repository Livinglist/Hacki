import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:logger/logger.dart';

part 'fav_state.dart';

class FavCubit extends Cubit<FavState> {
  FavCubit({
    required AuthBloc authBloc,
    AuthRepository? authRepository,
    PreferenceRepository? preferenceRepository,
    HackerNewsRepository? hackerNewsRepository,
    HackerNewsWebRepository? hackerNewsWebRepository,
    Logger? logger,
  })  : _authBloc = authBloc,
        _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        _hackerNewsWebRepository =
            hackerNewsWebRepository ?? locator.get<HackerNewsWebRepository>(),
        _logger = logger ?? locator.get<Logger>(),
        super(FavState.init()) {
    init();
  }

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;
  final HackerNewsRepository _hackerNewsRepository;
  final HackerNewsWebRepository _hackerNewsWebRepository;
  final Logger _logger;
  late final StreamSubscription<String>? _usernameSubscription;
  static const int _pageSize = 20;

  Future<void> init() async {
    _usernameSubscription = _authBloc.stream
        .map((AuthState event) => event.username)
        .distinct()
        .listen((String username) {
      _preferenceRepository.favList(of: username).then((List<int> favIds) {
        emit(
          state.copyWith(
            favIds: LinkedHashSet<int>.from(favIds).toList(),
            favItems: <Item>[],
            currentPage: 0,
          ),
        );
        _hackerNewsRepository
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
    });
  }

  Future<void> addFav(int id) async {
    if (state.favIds.contains(id)) return;

    await _preferenceRepository.addFav(username: username, id: id);

    emit(
      state.copyWith(
        favIds: List<int>.from(state.favIds)..add(id),
      ),
    );

    final Item? item = await _hackerNewsRepository.fetchItem(id: id);

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
    _preferenceRepository
      ..removeFav(username: username, id: id)
      ..removeFav(username: '', id: id);

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

      _hackerNewsRepository
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
    emit(
      state.copyWith(
        status: Status.inProgress,
        currentPage: 0,
        favItems: <Item>[],
        favIds: <int>[],
      ),
    );

    _preferenceRepository.favList(of: username).then((List<int> favIds) {
      emit(state.copyWith(favIds: LinkedHashSet<int>.from(favIds).toList()));
      _hackerNewsRepository
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

  Future<void> merge({
    required AppExceptionHandler onError,
    required VoidCallback onSuccess,
  }) async {
    if (_authBloc.state.isLoggedIn) {
      emit(state.copyWith(mergeStatus: Status.inProgress));
      try {
        final Iterable<int> ids = await _hackerNewsWebRepository.fetchFavorites(
          of: _authBloc.state.username,
        );
        _logger.d('fetched ${ids.length} favorite items from HN.');
        final List<int> combinedIds = <int>[...ids, ...state.favIds];
        final LinkedHashSet<int> mergedIds =
            LinkedHashSet<int>.from(combinedIds);
        await _preferenceRepository.overwriteFav(
          username: username,
          ids: mergedIds,
        );
        emit(state.copyWith(mergeStatus: Status.success));
        onSuccess();
        refresh();
      } on RateLimitedException catch (e) {
        onError(e);
        emit(state.copyWith(mergeStatus: Status.failure));
      }
    }
  }

  void _onItemLoaded(Item item) {
    emit(
      state.copyWith(
        favItems: List<Item>.from(state.favItems)..add(item),
      ),
    );
  }

  @override
  Future<void> close() {
    _usernameSubscription?.cancel();
    return super.close();
  }
}

extension on FavCubit {
  String get username => _authBloc.state.username;
}
