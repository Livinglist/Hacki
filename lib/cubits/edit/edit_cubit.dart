import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
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
    clear();
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

  bool called = false;

  @override
  EditState? fromJson(Map<String, dynamic> json) {
    final String text = json['text'] as String? ?? '';
    final Map<String, dynamic>? itemJson =
        json['item'] as Map<String, dynamic>?;
    final Item? replyingTo = itemJson == null ? null : Item.fromJson(itemJson);

    if (replyingTo != null && text.isNotEmpty) {
      _draftCache.cacheDraft(text: text, replyingTo: replyingTo.id);

      final EditState state = EditState(
        text: text,
        replyingTo: replyingTo,
      );

      _cachedState = state;

      return state;
    }

    return state;
  }

  @override
  Map<String, dynamic>? toJson(EditState state) {
    EditState selected = state;

    if (state.replyingTo == null ||
        (state.replyingTo?.id != _cachedState.replyingTo?.id &&
            state.text.isNullOrEmpty)) {
      selected = _cachedState;
    }

    return <String, dynamic>{
      'text': selected.text,
      'item': selected.replyingTo?.toJson(),
    };
  }

  static EditState _cachedState = const EditState.init();
}
