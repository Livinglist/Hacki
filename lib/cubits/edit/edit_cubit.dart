import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/debouncer.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'edit_state.dart';

class EditCubit extends HydratedCubit<EditState> {
  EditCubit({DraftCache? draftCache})
      : _draftCache = draftCache ?? locator.get<DraftCache>(),
        _debouncer = Debouncer(delay: const Duration(seconds: 1)),
        super(const EditState.init());

  final DraftCache _draftCache;
  final Debouncer _debouncer;

  void onReplyTapped(Item item) {
    emit(
      EditState(
        replyingTo: item,
        text: _draftCache.getDraft(replyingTo: item.id),
      ),
    );
  }

  void onEditTapped(Item itemToBeEdited) {
    emit(
      EditState(
        itemBeingEdited: itemToBeEdited,
        text: itemToBeEdited.text,
      ),
    );
  }

  void onReplyBoxClosed() {
    emit(const EditState.init());
  }

  void onScrolled() {
    emit(const EditState.init());
  }

  void onReplySubmittedSuccessfully() {
    if (state.replyingTo != null) {
      _draftCache.removeDraft(replyingTo: state.replyingTo!.id);
    }
    emit(const EditState.init());
  }

  void onTextChanged(String text) {
    emit(state.copyWith(text: text));
    if (state.replyingTo != null) {
      final int? id = state.replyingTo?.id;
      _debouncer.run(() {
        _draftCache.cacheDraft(
          text: text,
          replyingTo: id!,
        );
      });
    }
  }

  void deleteDraft() => clear();

  @override
  EditState? fromJson(Map<String, dynamic> json) {
    final String text = json['text'] as String? ?? '';
    final Map<String, dynamic>? itemJson =
        json['item'] as Map<String, dynamic>?;
    final Item? replyingTo = itemJson == null ? null : Item.fromJson(itemJson);
    if (replyingTo != null) {
      _draftCache.cacheDraft(text: text, replyingTo: replyingTo.id);
    }

    if (text.isEmpty) return state;

    cachedState = json;

    return EditState(
      text: text,
      replyingTo: replyingTo,
    );
  }

  @override
  Map<String, dynamic>? toJson(EditState state) {
    if (state.text?.isEmpty ?? true) return cachedState;

    return <String, dynamic>{
      'text': state.text,
      'item': state.replyingTo?.toJson(),
    };
  }

  static Map<String, dynamic> cachedState = <String, dynamic>{};
}
