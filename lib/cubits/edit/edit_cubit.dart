import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/debouncer.dart';

part 'edit_state.dart';

class EditCubit extends Cubit<EditState> {
  EditCubit({CacheService? cacheService})
      : _cacheService = cacheService ?? locator.get<CacheService>(),
        _debouncer = Debouncer(delay: const Duration(seconds: 1)),
        super(const EditState.init());

  final CacheService _cacheService;
  final Debouncer _debouncer;

  void onItemTapped(Item item) {
    if (item.dead || item.deleted) {
      return;
    }

    emit(EditState(
      replyingTo: item,
      text: _cacheService.getDraft(replyingTo: item.id),
    ));
  }

  void onReplyBoxClosed() {
    emit(const EditState.init());
  }

  void onScrolled() {
    emit(const EditState.init());
  }

  void onReplySubmittedSuccessfully() {
    if (state.replyingTo != null) {
      _cacheService.removeDraft(replyingTo: state.replyingTo!.id);
    }
    emit(const EditState.init());
  }

  void onTextChanged(String text) {
    emit(state.copyWith(text: text));
    if (state.replyingTo != null) {
      final id = state.replyingTo?.id;
      _debouncer.run(() {
        _cacheService.cacheDraft(
          text: text,
          replyingTo: id!,
        );
      });
    }
  }
}
