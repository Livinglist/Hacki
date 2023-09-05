part of 'notification_cubit.dart';

class NotificationState extends Equatable {
  const NotificationState({
    required this.comments,
    required this.unreadCommentsIds,
    required this.allCommentsIds,
    required this.currentPage,
    required this.offset,
    required this.status,
  });

  NotificationState.init()
      : comments = <Comment>[],
        unreadCommentsIds = <int>[],
        allCommentsIds = <int>[],
        currentPage = 0,
        offset = 0,
        status = Status.idle;

  final List<Comment> comments;
  final List<int> allCommentsIds;
  final List<int> unreadCommentsIds;
  final int currentPage;
  final int offset;
  final Status status;

  NotificationState copyWith({
    List<Comment>? comments,
    List<int>? allCommentsIds,
    List<int>? unreadCommentsIds,
    int? currentPage,
    int? offset,
    Status? status,
  }) {
    return NotificationState(
      comments: comments ?? this.comments,
      allCommentsIds: allCommentsIds ?? this.allCommentsIds,
      unreadCommentsIds: unreadCommentsIds ?? this.unreadCommentsIds,
      currentPage: currentPage ?? this.currentPage,
      offset: offset ?? this.offset,
      status: status ?? this.status,
    );
  }

  NotificationState copyWithCommentMarkedRead({required int commentId}) {
    return NotificationState(
      comments: comments,
      allCommentsIds: allCommentsIds,
      unreadCommentsIds: <int>[...unreadCommentsIds]..remove(commentId),
      currentPage: currentPage,
      offset: offset,
      status: status,
    );
  }

  NotificationState copyWithNewUnreadComment({required Comment comment}) {
    return NotificationState(
      comments: <Comment>[comment, ...comments]
        ..sort((Comment lhs, Comment rhs) => rhs.time.compareTo(lhs.time)),
      allCommentsIds:
          (<int>[comment.id, ...allCommentsIds]..sort()).reversed.toList(),
      unreadCommentsIds:
          (<int>[comment.id, ...unreadCommentsIds]..sort()).reversed.toList(),
      currentPage: currentPage,
      offset: offset + 1,
      status: status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        currentPage,
        offset,
        status,
        comments,
        unreadCommentsIds,
        allCommentsIds,
      ];
}
