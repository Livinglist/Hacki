import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> with Loggable {
  NotificationCubit({
    required AuthBloc authBloc,
    required PreferenceCubit preferenceCubit,
    HackerNewsRepository? hackerNewsRepository,
    PreferenceRepository? preferenceRepository,
    SembastRepository? sembastRepository,
  }) : _authBloc = authBloc,
       _preferenceCubit = preferenceCubit,
       _hackerNewsRepository =
           hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
       _preferenceRepository =
           preferenceRepository ?? locator.get<PreferenceRepository>(),
       _sembastRepository =
           sembastRepository ?? locator.get<SembastRepository>(),
       super(NotificationState.init()) {
    _authBloc.stream.map((AuthState event) => event.username).distinct().listen(
      (String username) {
        if (username.isNotEmpty) {
          // Get the user setting.
          if (_preferenceCubit.state.isNotificationEnabled) {
            Future<void>.delayed(AppDurations.twoSeconds, init);
          }

          // Listen for setting changes in the future.
          _preferenceCubit.stream.listen((PreferenceState prefState) {
            final bool isActive = _timer?.isActive ?? false;
            if (prefState.isNotificationEnabled && !isActive) {
              init();
            } else if (!prefState.isNotificationEnabled) {
              _timer?.cancel();
            }
          });
        } else {
          emit(NotificationState.init());
        }
      },
    );
  }

  final AuthBloc _authBloc;
  final PreferenceCubit _preferenceCubit;
  final HackerNewsRepository _hackerNewsRepository;
  final PreferenceRepository _preferenceRepository;
  final SembastRepository _sembastRepository;
  Timer? _timer;

  static const Duration _refreshInterval = Duration(minutes: 5);
  static const int _subscriptionUpperLimit = 15;
  static const int _pageSize = 20;

  Future<void> init() async {
    emit(NotificationState.init());

    await _sembastRepository.getIdsOfCommentsRepliedToMe().then((
      List<int> commentIds,
    ) {
      emit(state.copyWith(allCommentsIds: commentIds));
    });

    await _preferenceRepository.unreadCommentsIds.then((List<int> unreadIds) {
      logInfo('${unreadIds.length} unread items.');
      emit(state.copyWith(unreadCommentsIds: unreadIds));
    });

    final List<int> commentsToBeLoaded = state.allCommentsIds.sublist(
      0,
      min(state.allCommentsIds.length, _pageSize),
    );

    for (final int id in commentsToBeLoaded) {
      Comment? comment = await _sembastRepository.getComment(id: id);
      comment ??= await _hackerNewsRepository.fetchComment(id: id);
      if (comment != null) {
        emit(state.copyWith(comments: <Comment>[...state.comments, comment]));
      }
    }

    await _fetchReplies().whenComplete(_initializeTimer);
  }

  void markAsRead(int id) {
    if (state.unreadCommentsIds.contains(id)) {
      final List<int> updatedUnreadIds = <int>[...state.unreadCommentsIds]
        ..remove(id);
      _preferenceRepository.updateUnreadCommentsIds(updatedUnreadIds);
      emit(state.copyWith(unreadCommentsIds: updatedUnreadIds));
    }
  }

  void markAllAsRead() {
    emit(state.copyWith(unreadCommentsIds: <int>[]));
    _preferenceRepository.updateUnreadCommentsIds(<int>[]);
  }

  Future<void> refresh() async {
    if (_authBloc.state.isLoggedIn &&
        _preferenceCubit.state.isNotificationEnabled) {
      emit(state.copyWith(status: Status.inProgress));

      _timer?.cancel();

      await _fetchReplies().whenComplete(_initializeTimer);
    } else {
      emit(state.copyWith(status: Status.success));
    }
  }

  Future<void> loadMore() async {
    emit(state.copyWith(status: Status.inProgress));

    final int currentPage = state.currentPage + 1;
    final int lower = currentPage * _pageSize + state.offset;
    final int upper = min(lower + _pageSize, state.allCommentsIds.length);

    if (lower < upper) {
      final List<int> commentsToBeLoaded = state.allCommentsIds.sublist(
        lower,
        upper,
      );

      for (final int id in commentsToBeLoaded) {
        Comment? comment = await _sembastRepository.getComment(id: id);
        comment ??= await _hackerNewsRepository.fetchComment(id: id);
        if (comment != null) {
          emit(state.copyWith(comments: <Comment>[...state.comments, comment]));
        }
      }
    }

    emit(state.copyWith(status: Status.success, currentPage: currentPage));
  }

  void _initializeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (Timer timer) => _fetchReplies());
  }

  Future<void> _fetchReplies() {
    return _hackerNewsRepository
        .fetchSubmitted(userId: _authBloc.state.username)
        .then((List<int>? submittedItems) async {
          if (submittedItems != null) {
            final List<int> subscribedItems = submittedItems.sublist(
              0,
              min(_subscriptionUpperLimit, submittedItems.length),
            );

            for (final int id in subscribedItems) {
              final Item? item = await _hackerNewsRepository.fetchItem(id: id);
              // A failed fetch must not wipe the stored kids snapshot,
              // otherwise the next successful fetch treats every reply as new.
              if (item == null) continue;

              final List<int> kids = item.kids;
              final List<int>? previousKids = await _sembastRepository.kids(
                of: id,
              );

              // An empty kids list after we already had replies is more likely
              // a bad payload than every child disappearing at once.
              if (previousKids != null &&
                  previousKids.isNotEmpty &&
                  kids.isEmpty) {
                continue;
              }

              await _sembastRepository.updateKidsOf(id: id, kids: kids);

              // `null` means there is no snapshot yet (first run or cache
              // cleared). Record the current kids as the baseline instead of
              // marking every existing reply unread.
              final bool isFirstSnapshot = previousKids == null;
              final Set<int> diff = <int>{
                ...kids,
              }.difference(<int>{...?previousKids});

              for (final int newCommentId in diff) {
                await _processReply(
                  commentId: newCommentId,
                  markUnread: !isFirstSnapshot,
                );
              }
            }
          }
        })
        .whenComplete(() {
          logInfo('${state.allCommentsIds.length} replies were fetched.');
          emit(state.copyWith(status: Status.success));
        });
  }

  Future<void> _processReply({
    required int commentId,
    required bool markUnread,
  }) async {
    if (state.allCommentsIds.contains(commentId)) return;

    final bool hasPushed = await _preferenceRepository.hasPushed(commentId);

    final Comment? comment = await _hackerNewsRepository.fetchComment(
      id: commentId,
    );
    if (comment == null || comment.dead || comment.deleted) return;
    if (comment.by == _authBloc.state.username) return;

    await _sembastRepository.saveComment(comment);
    await _sembastRepository.updateIdsOfCommentsRepliedToMe(comment.id);

    final bool alreadyUnread = state.unreadCommentsIds.contains(comment.id);
    final bool shouldMarkUnread = markUnread && !hasPushed && !alreadyUnread;

    if (shouldMarkUnread) {
      await _preferenceRepository.updateUnreadCommentsIds(
        <int>[comment.id, ...state.unreadCommentsIds]
          ..sort((int lhs, int rhs) => rhs.compareTo(lhs)),
      );
      emit(state.copyWithNewUnreadComment(comment: comment));
    } else {
      emit(state.copyWithNewComment(comment: comment));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void onCommentTapped(
    Comment comment, {
    void Function((Story, List<Comment>)? res)? then,
  }) {
    if (state.commentFetchingStatus == Status.inProgress) return;

    emit(
      state.copyWith(
        commentFetchingStatus: Status.inProgress,
        tappedCommentId: comment.id,
      ),
    );

    locator
        .get<HackerNewsRepository>()
        .fetchParentStoryWithComments(id: comment.parent)
        .then(((Story, List<Comment>)? res) {
          emit(state.copyWith(commentFetchingStatus: Status.success));
          then?.call(res);
        });
  }

  @override
  String get logIdentifier => 'NotificationCubit';
}
