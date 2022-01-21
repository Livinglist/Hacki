import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    required AuthBloc authBloc,
    StoriesRepository? storiesRepository,
    StorageRepository? storageRepository,
    SembastRepository? sembastRepository,
  })  : _authBloc = authBloc,
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(NotificationState.init()) {
    _authBloc.stream.listen((authState) {
      if (authState.isLoggedIn && authState.username != _username) {
        init();
        _username = authState.username;
      }
    });
  }

  final AuthBloc _authBloc;
  final StoriesRepository _storiesRepository;
  final StorageRepository _storageRepository;
  final SembastRepository _sembastRepository;
  String? _username;

  static const _refreshDuration = Duration(minutes: 3);
  static const _subscriptionUpperLimit = 15;
  static const _pageSize = 20;

  Future<void> init() async {
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

    Timer.periodic(_refreshDuration, (timer) {
      _storiesRepository
          .fetchSubmitted(of: _authBloc.state.username)
          .then((submittedItems) {
        if (submittedItems != null) {
          final subscribedItems = submittedItems.sublist(
            0,
            min(_subscriptionUpperLimit, submittedItems.length),
          );

          for (final id in subscribedItems) {
            _storiesRepository.fetchItemBy(id: id).then((item) async {
              final kids = item?.kids ?? <int>[];
              final previousKids =
                  await _storageRepository.kids(of: id.toString());

              await _storageRepository.updateKidsOf(
                  id: id.toString(), kids: kids);

              if (previousKids != null && previousKids.length != kids.length) {
                final diff = {...kids}.difference({...previousKids});

                for (final newCommentId in diff) {
                  await _storageRepository.updateUnreadCommentsIds([
                    newCommentId,
                    ...state.unreadCommentsIds,
                  ]);
                  await _storiesRepository
                      .fetchCommentBy(id: newCommentId)
                      .then((comment) {
                    if (comment != null && !comment.dead && !comment.deleted) {
                      _sembastRepository
                        ..saveComment(comment)
                        ..updateIdsOfCommentsRepliedToMe(comment.id);
                      emit(state.copyWithNewUnreadComment(comment: comment));
                    }
                  });
                }
              }
            });
          }
        }
      });
    });
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

  Future<void> loadMore() async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final currentPage = state.currentPage + 1;
    final lower = currentPage * _pageSize + state.offset;
    final upper = min(lower + _pageSize, state.allCommentsIds.length);
    final commentsToBeLoaded = state.allCommentsIds.sublist(lower, upper);

    for (final id in commentsToBeLoaded) {
      var comment = await _sembastRepository.getComment(id: id);
      comment ??= await _storiesRepository.fetchCommentBy(id: id);
      if (comment != null) {
        emit(state.copyWith(comments: [...state.comments, comment]));
      }
    }

    emit(state.copyWith(
      status: NotificationStatus.loaded,
      currentPage: currentPage,
    ));
  }
}
