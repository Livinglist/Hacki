import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  PostCubit({
    PostRepository? postRepository,
  })  : _postRepository = postRepository ?? locator.get<PostRepository>(),
        super(const PostState.init());

  final PostRepository _postRepository;

  Future<void> post({required String text, required int to}) async {
    emit(state.copyWith(status: Status.inProgress));

    final bool successful = await _postRepository.comment(
      parentId: to,
      text: text,
    );

    if (successful) {
      emit(state.copyWith(status: Status.success));
    } else {
      emit(state.copyWith(status: Status.failure));
    }
  }

  Future<void> edit({required String text, required int id}) async {
    emit(state.copyWith(status: Status.inProgress));
    final bool successful = await _postRepository.edit(id: id, text: text);

    if (successful) {
      emit(state.copyWith(status: Status.success));
    } else {
      emit(state.copyWith(status: Status.failure));
    }
  }

  void reset() {
    emit(state.copyWith(status: Status.idle));
  }

  @Deprecated('For debugging only')
  Future<bool> getFakeResult() async {
    final bool result = await Future<bool>.delayed(
      const Duration(seconds: 2),
      () => true,
    );
    return result;
  }
}
