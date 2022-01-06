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
  static const _pageSize = 20;

  void init() {
    _authBloc.stream.listen((authState) {
      if (authState.isLoggedIn) {
        final username = authState.username;

        _storiesRepository.fetchSubmitted(of: username).then((submittedIds) {
          emit(state.copyWith(
            submittedIds: submittedIds,
            submittedItems: [],
            currentPage: 0,
          ));
          if (submittedIds != null) {
            _storiesRepository
                .fetchItemsStream(
                    ids: submittedIds.sublist(
                        0, _pageSize.clamp(0, submittedIds.length)))
                .listen(_onItemLoaded);
          }
        });
        return;
      }
    });
  }

  void loadMore() {
    emit(state.copyWith(status: HistoryStatus.loading));
    final currentPage = state.currentPage;
    final len = state.submittedIds.length;
    emit(state.copyWith(currentPage: currentPage + 1));
    final lower = _pageSize * (currentPage + 1);
    var upper = _pageSize + _pageSize * (currentPage + 1);

    if (len > lower) {
      if (len < upper) {
        upper = len;
      }

      _storiesRepository
          .fetchStoriesStream(
              ids: state.submittedIds.sublist(
            lower,
            upper,
          ))
          .listen(_onItemLoaded)
          .onDone(() {
        emit(state.copyWith(status: HistoryStatus.loaded));
      });
    } else {
      emit(state.copyWith(status: HistoryStatus.loaded));
    }
  }

  void refresh() {
    final username = _authBloc.state.username;
    emit(state.copyWith(
      status: HistoryStatus.loading,
      currentPage: 0,
      submittedIds: [],
      submittedItems: [],
    ));

    _storiesRepository.fetchSubmitted(of: username).then((submittedIds) {
      emit(state.copyWith(submittedIds: submittedIds));
      if (submittedIds != null) {
        _storiesRepository
            .fetchItemsStream(
                ids: submittedIds.sublist(
                    0, _pageSize.clamp(0, submittedIds.length)))
            .listen(_onItemLoaded)
            .onDone(() {
          emit(state.copyWith(status: HistoryStatus.loaded));
        });
      }
    });
  }

  void reset() {
    emit(state.copyWith(
      submittedIds: [],
      submittedItems: [],
      currentPage: 0,
    ));
  }

  void _onItemLoaded(Item item) {
    emit(state.copyWith(
        submittedItems: List<Item>.from(state.submittedItems)..add(item)));
  }
}
