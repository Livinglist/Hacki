part of 'edit_cubit.dart';

class EditState extends Equatable {
  const EditState({
    this.text,
    this.replyingTo,
  });

  const EditState.init()
      : text = null,
        replyingTo = null;

  final String? text;
  final Item? replyingTo;

  bool get showReplyBox => replyingTo != null;

  EditState copyWith({String? text}) {
    return EditState(
      replyingTo: replyingTo,
      text: text ?? this.text,
    );
  }

  @override
  List<Object?> get props => [
        text,
        replyingTo,
      ];
}
