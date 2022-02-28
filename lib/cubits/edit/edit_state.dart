part of 'edit_cubit.dart';

class EditState extends Equatable {
  const EditState({
    this.text,
    this.replyingTo,
    this.itemBeingEdited,
  });

  const EditState.init()
      : text = null,
        replyingTo = null,
        itemBeingEdited = null;

  final String? text;
  final Item? replyingTo;
  final Item? itemBeingEdited;

  bool get showReplyBox => replyingTo != null;

  EditState copyWith({String? text}) {
    return EditState(
      replyingTo: replyingTo,
      itemBeingEdited: itemBeingEdited,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [
        text,
        replyingTo,
        itemBeingEdited,
      ];
}
