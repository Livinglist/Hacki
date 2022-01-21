part of 'notification_cubit.dart';

enum NotificationStatus {
  initial,
  loading,
  loaded,
  failure,
}

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
      : comments = [],
        unreadCommentsIds = [],
        allCommentsIds = [],
        currentPage = 0,
        offset = 0,
        status = NotificationStatus.initial;

  final List<Comment> comments;
  final List<int> allCommentsIds;
  final List<int> unreadCommentsIds;
  final int currentPage;
  final int offset;
  final NotificationStatus status;

  NotificationState copyWith({
    List<Comment>? comments,
    List<int>? allCommentsIds,
    List<int>? unreadCommentsIds,
    int? currentPage,
    int? offset,
    NotificationStatus? status,
  }) {
    print('NotificationState ${unreadCommentsIds ?? this.unreadCommentsIds}');
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
      unreadCommentsIds: [...unreadCommentsIds]..remove(commentId),
      currentPage: currentPage,
      offset: offset,
      status: status,
    );
  }

  NotificationState copyWithNewUnreadComment({required Comment comment}) {
    print(([comment.id, ...unreadCommentsIds]..sort()).reversed.toList());
    return NotificationState(
      comments: [comment, ...comments]
        ..sort((lhs, rhs) => rhs.time.compareTo(lhs.time)),
      allCommentsIds:
          ([comment.id, ...allCommentsIds]..sort()).reversed.toList(),
      unreadCommentsIds:
          ([comment.id, ...unreadCommentsIds]..sort()).reversed.toList(),
      currentPage: currentPage,
      offset: offset + 1,
      status: status,
    );
  }

  @override
  List<Object?> get props => [
        comments,
        unreadCommentsIds,
        allCommentsIds,
        currentPage,
        offset,
        status,
      ];
}
