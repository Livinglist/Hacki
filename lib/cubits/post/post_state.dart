part of 'post_cubit.dart';

class PostState extends Equatable {
  const PostState({
    required this.status,
    this.parentId,
    this.editedId,
    this.text,
  });

  const PostState.init()
    : status = Status.idle,
      parentId = null,
      editedId = null,
      text = null;

  final Status status;

  /// The id of the item that was replied to, once a reply has been posted.
  final int? parentId;

  /// The id of the comment that was edited, once an edit has been posted.
  final int? editedId;

  /// The text that was posted.
  final String? text;

  PostState copyWith({Status? status}) {
    return PostState(
      status: status ?? this.status,
      parentId: parentId,
      editedId: editedId,
      text: text,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, parentId, editedId, text];
}
