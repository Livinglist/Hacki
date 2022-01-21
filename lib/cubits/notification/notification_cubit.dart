import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
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
    StorageRepository? storageRepository,
    SembastRepository? sembastRepository,
  })  : _authBloc = authBloc,
        _preferenceCubit = preferenceCubit,
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(NotificationState.init()) {
    _authBloc.stream.listen((authState) {
      if (authState.isLoggedIn && authState.username != _username) {
        // Get the user setting.
        _storageRepository.shouldShowNotification.then((showNotification) {
          if (showNotification) {
            init();
          }
        });

        // Listen for setting changes in the future.
        _preferenceCubit.stream.listen((prefState) {
          final isActive = _timer?.isActive ?? false;
          if (prefState.showNotification && !isActive) {
            init();
          } else if (!prefState.showNotification) {
            _timer?.cancel();
          }
        });

        _username = authState.username;
      }
    });
  }

  final AuthBloc _authBloc;
  final PreferenceCubit _preferenceCubit;
  final StoriesRepository _storiesRepository;
  final StorageRepository _storageRepository;
  final SembastRepository _sembastRepository;
  String? _username;
  Timer? _timer;

  static const _refreshDuration = Duration(minutes: 1);
  static const _subscriptionUpperLimit = 15;
  static const _pageSize = 20;

  Future<void> init() async {
    emit(NotificationState.init());

    await _sembastRepository.getIdsOfCommentsRepliedToMe().then((commentIds) {
      emit(state.copyWith(allCommentsIds: commentIds));
    });

    await _storageRepository.unreadCommentsIds.then((unreadIds) {
      emit(state.copyWith(unreadCommentsIds: unreadIds));
    });

    final commentsToBeLoaded = state.allCommentsIds
        .sublist(0, min(state.allCommentsIds.length, _pageSize));
    for (final id in commentsToBeLoaded) {
      var comment = await _sembastRepository.getComment(id: id);
      comment ??= await _storiesRepository.fetchCommentBy(id: id);
      if (comment != null) {
        emit(state.copyWith(comments: [
          ...state.comments,
          comment,
        ]));
      }
    }

    await _fetchReplies().whenComplete(() {
      emit(state.copyWith(
        status: NotificationStatus.loaded,
      ));
      _initializeTimer();
    }).onError((error, stackTrace) => _initializeTimer());
  }

  void markAsRead(Comment comment) {
    if (state.unreadCommentsIds.contains(comment.id)) {
      final updatedUnreadIds = [...state.unreadCommentsIds]..remove(comment.id);
      _storageRepository.updateUnreadCommentsIds(updatedUnreadIds);
      emit(state.copyWith(unreadCommentsIds: updatedUnreadIds));
    }
  }

  void markAllAsRead() {
    emit(state.copyWith(unreadCommentsIds: []));
    _storageRepository.updateUnreadCommentsIds([]);
  }

  Future<void> refresh() async {
    if (_authBloc.state.isLoggedIn && _preferenceCubit.state.showNotification) {
      emit(state.copyWith(
        status: NotificationStatus.loading,
      ));

      _timer?.cancel();

      await _fetchReplies().whenComplete(() {
        emit(state.copyWith(
          status: NotificationStatus.loaded,
        ));
        _initializeTimer();
      }).onError((error, stackTrace) {
        emit(state.copyWith(
          status: NotificationStatus.loaded,
        ));
        _initializeTimer();
      });
    } else {
      emit(state.copyWith(
        status: NotificationStatus.loaded,
      ));
    }
  }

  Future<void> loadMore() async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final currentPage = state.currentPage + 1;
    final lower = currentPage * _pageSize + state.offset;
    final upper = min(lower + _pageSize, state.allCommentsIds.length);

    if (lower < upper) {
      final commentsToBeLoaded = state.allCommentsIds.sublist(lower, upper);

      for (final id in commentsToBeLoaded) {
        var comment = await _sembastRepository.getComment(id: id);
        comment ??= await _storiesRepository.fetchCommentBy(id: id);
        if (comment != null) {
          emit(state.copyWith(comments: [...state.comments, comment]));
        }
      }
    }

    emit(state.copyWith(
      status: NotificationStatus.loaded,
      currentPage: currentPage,
    ));
  }

  void _initializeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshDuration, (timer) => _fetchReplies());
  }

  Future<void> _fetchReplies() {
    return _storiesRepository
        .fetchSubmitted(of: _authBloc.state.username)
        .then((submittedItems) async {
      if (submittedItems != null) {
        final subscribedItems = submittedItems.sublist(
          0,
          min(_subscriptionUpperLimit, submittedItems.length),
        );

        for (final id in subscribedItems) {
          await _storiesRepository.fetchItemBy(id: id).then((item) async {
            final kids = item?.kids ?? [];
            final previousKids = (await _sembastRepository.kids(of: id)) ?? [];

            await _sembastRepository.updateKidsOf(id: id, kids: kids);

            if (previousKids.length != kids.length) {
              final diff = {...kids}.difference({...previousKids});

              for (final newCommentId in diff) {
                await _storageRepository.updateUnreadCommentsIds([
                  newCommentId,
                  ...state.unreadCommentsIds,
                ]..sort((lhs, rhs) => rhs.compareTo(lhs)));
                await _storiesRepository
                    .fetchCommentBy(id: newCommentId)
                    .then((comment) {
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
          });
        }
      }
    });
  }
}
