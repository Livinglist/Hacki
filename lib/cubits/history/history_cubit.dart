import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required AuthBloc authBloc,
    StoriesRepository? storiesRepository,
  })  : _authBloc = authBloc,
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(HistoryState.init()) {
    init();
  }

  final AuthBloc _authBloc;
  final StoriesRepository _storiesRepository;
  static const int _pageSize = 20;

  void init() {
    _authBloc.stream.listen((AuthState authState) {
      if (authState.isLoggedIn) {
        final String username = authState.username;

        _storiesRepository
            .fetchSubmitted(userId: username)
            .then((List<int>? submittedIds) {
          emit(
            state.copyWith(
              submittedIds: submittedIds,
              submittedItems: <Item>[],
              currentPage: 0,
            ),
          );
          if (submittedIds != null) {
            _storiesRepository
                .fetchItemsStream(
                  ids: submittedIds.sublist(
                    0,
                    _pageSize.clamp(0, submittedIds.length),
                  ),
                )
                .listen(_onItemLoaded);
          }
        });
        return;
      }
    });
  }

  void loadMore() {
    emit(state.copyWith(status: HistoryStatus.loading));
    final int currentPage = state.currentPage;
    final int len = state.submittedIds.length;
    emit(state.copyWith(currentPage: currentPage + 1));
    final int lower = _pageSize * (currentPage + 1);
    int upper = _pageSize + lower;

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      _storiesRepository
          .fetchItemsStream(
            ids: state.submittedIds.sublist(
              lower,
              upper,
            ),
          )
          .listen(_onItemLoaded)
          .onDone(() {
        emit(state.copyWith(status: HistoryStatus.loaded));
      });
    } else {
      emit(state.copyWith(status: HistoryStatus.loaded));
    }
  }

  void refresh() {
    final String username = _authBloc.state.username;
    emit(
      state.copyWith(
        status: HistoryStatus.loading,
        currentPage: 0,
        submittedIds: <int>[],
        submittedItems: <Item>[],
      ),
    );

    _storiesRepository
        .fetchSubmitted(userId: username)
        .then((List<int>? submittedIds) {
      emit(state.copyWith(submittedIds: submittedIds));
      if (submittedIds != null) {
        _storiesRepository
            .fetchItemsStream(
              ids: submittedIds.sublist(
                0,
                _pageSize.clamp(0, submittedIds.length),
              ),
            )
            .listen(_onItemLoaded)
            .onDone(() {
          emit(state.copyWith(status: HistoryStatus.loaded));
        });
      }
    });
  }

  void reset() {
    emit(
      state.copyWith(
        submittedIds: <int>[],
        submittedItems: <Item>[],
        currentPage: 0,
      ),
    );
  }

  void _onItemLoaded(Item item) {
    emit(
      state.copyWith(
        submittedItems: List<Item>.from(state.submittedItems)..add(item),
      ),
    );
  }
}
