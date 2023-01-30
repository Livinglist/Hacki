import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required AuthBloc authBloc,
    required PreferenceCubit preferenceCubit,
    StoriesRepository? storiesRepository,
    PreferenceRepository? preferenceRepository,
    SembastRepository? sembastRepository,
  })  : _authBloc = authBloc,
        _preferenceCubit = preferenceCubit,
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(NotificationState.init()) {
    _authBloc.stream.listen((AuthState authState) {
      if (authState.isLoggedIn && authState.username != _username) {
        // Get the user setting.
        if (_preferenceCubit.state.notificationEnabled) {
          Future<void>.delayed(const Duration(seconds: 2), init);
        }

        // Listen for setting changes in the future.
        _preferenceCubit.stream.listen((PreferenceState prefState) {
          final bool isActive = _timer?.isActive ?? false;
          if (prefState.notificationEnabled && !isActive) {
            init();
          } else if (!prefState.notificationEnabled) {
            _timer?.cancel();
          }
        });

        _username = authState.username;
      } else if (!authState.isLoggedIn) {
        emit(NotificationState.init());
      }
    });
  }

  final AuthBloc _authBloc;
  final PreferenceCubit _preferenceCubit;
  final StoriesRepository _storiesRepository;
  final PreferenceRepository _preferenceRepository;
  final SembastRepository _sembastRepository;
  String? _username;
  Timer? _timer;

  static const Duration _refreshInterval = Duration(minutes: 5);
  static const int _subscriptionUpperLimit = 15;
  static const int _pageSize = 20;

  Future<void> init() async {
    emit(NotificationState.init());

    await _sembastRepository
        .getIdsOfCommentsRepliedToMe()
        .then((List<int> commentIds) {
      emit(state.copyWith(allCommentsIds: commentIds));
    });

    await _preferenceRepository.unreadCommentsIds.then((List<int> unreadIds) {
      emit(state.copyWith(unreadCommentsIds: unreadIds));
    });

    final List<int> commentsToBeLoaded = state.allCommentsIds
        .sublist(0, min(state.allCommentsIds.length, _pageSize));

    for (final int id in commentsToBeLoaded) {
      Comment? comment = await _sembastRepository.getComment(id: id);
      comment ??= await _storiesRepository.fetchCommentBy(id: id);
      if (comment != null) {
        emit(
          state.copyWith(
            comments: <Comment>[
              ...state.comments,
              comment,
            ],
          ),
        );
      }
    }

    await _fetchReplies().whenComplete(_initializeTimer);
  }

  void markAsRead(int id) {
    Future.doWhile(() {
      if (state.status != NotificationStatus.loading) {
        if (state.unreadCommentsIds.contains(id)) {
          final List<int> updatedUnreadIds = <int>[...state.unreadCommentsIds]
            ..remove(id);
          _preferenceRepository.updateUnreadCommentsIds(updatedUnreadIds);
          emit(state.copyWith(unreadCommentsIds: updatedUnreadIds));
        }
        return false;
      }

      return true;
    });
  }

  void markAllAsRead() {
    Future.doWhile(() {
      if (state.status != NotificationStatus.loading) {
        emit(state.copyWith(unreadCommentsIds: <int>[]));
        _preferenceRepository.updateUnreadCommentsIds(<int>[]);
        return false;
      }

      return true;
    });
  }

  Future<void> refresh() async {
    if (_authBloc.state.isLoggedIn &&
        _preferenceCubit.state.notificationEnabled) {
      emit(
        state.copyWith(
          status: NotificationStatus.loading,
        ),
      );

      _timer?.cancel();

      await _fetchReplies().whenComplete(_initializeTimer);
    } else {
      emit(
        state.copyWith(
          status: NotificationStatus.loaded,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final int currentPage = state.currentPage + 1;
    final int lower = currentPage * _pageSize + state.offset;
    final int upper = min(lower + _pageSize, state.allCommentsIds.length);

    if (lower < upper) {
      final List<int> commentsToBeLoaded =
          state.allCommentsIds.sublist(lower, upper);

      for (final int id in commentsToBeLoaded) {
        Comment? comment = await _sembastRepository.getComment(id: id);
        comment ??= await _storiesRepository.fetchCommentBy(id: id);
        if (comment != null) {
          emit(state.copyWith(comments: <Comment>[...state.comments, comment]));
        }
      }
    }

    emit(
      state.copyWith(
        status: NotificationStatus.loaded,
        currentPage: currentPage,
      ),
    );
  }

  void _initializeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      _refreshInterval,
      (Timer timer) => _fetchReplies(),
    );
  }

  Future<void> _fetchReplies() {
    return _storiesRepository
        .fetchSubmitted(of: _authBloc.state.username)
        .then((List<int>? submittedItems) async {
      if (submittedItems != null) {
        final List<int> subscribedItems = submittedItems.sublist(
          0,
          min(_subscriptionUpperLimit, submittedItems.length),
        );

        for (final int id in subscribedItems) {
          await _storiesRepository.fetchItemBy(id: id).then((Item? item) async {
            final List<int> kids = item?.kids ?? <int>[];
            final List<int> previousKids =
                (await _sembastRepository.kids(of: id)) ?? <int>[];

            await _sembastRepository.updateKidsOf(id: id, kids: kids);

            final Set<int> diff =
                <int>{...kids}.difference(<int>{...previousKids});

            if (diff.isNotEmpty) {
              for (final int newCommentId in diff) {
                final bool hasPushed =
                    await _preferenceRepository.hasPushed(newCommentId);

                if (!hasPushed) {
                  await _preferenceRepository.updateUnreadCommentsIds(
                    <int>[
                      newCommentId,
                      ...state.unreadCommentsIds,
                    ]..sort((int lhs, int rhs) => rhs.compareTo(lhs)),
                  );
                  await _storiesRepository
                      .fetchCommentBy(id: newCommentId)
                      .then((Comment? comment) {
                    if (comment != null && !comment.dead && !comment.deleted) {
                      _sembastRepository
                        ..saveComment(comment)
                        ..updateIdsOfCommentsRepliedToMe(comment.id);

                      // Add comment fetched to comments
                      // and its id to unreadCommentsIds and allCommentsIds,
                      emit(state.copyWithNewUnreadComment(comment: comment));
                    }
                  });
                }
              }
            }
          });
        }
      }
    }).whenComplete(
      () => emit(
        state.copyWith(status: NotificationStatus.loaded),
      ),
    );
  }
}
