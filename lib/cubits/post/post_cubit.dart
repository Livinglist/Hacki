import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  PostCubit({
    PostRepository? postRepository,
  })  : _postRepository = postRepository ?? locator.get<PostRepository>(),
        super(const PostState.init());

  final PostRepository _postRepository;

  Future<void> post({required String text, required int to}) async {
    emit(state.copyWith(status: PostStatus.loading));
    final bool successful = await _postRepository.comment(
      parentId: to,
      text: text,
    );

    if (successful) {
      emit(state.copyWith(status: PostStatus.successful));
    } else {
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  Future<void> edit({required String text, required int id}) async {
    emit(state.copyWith(status: PostStatus.loading));
    final bool successful = await _postRepository.edit(id: id, text: text);

    if (successful) {
      emit(state.copyWith(status: PostStatus.successful));
    } else {
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  void reset() {
    emit(state.copyWith(status: PostStatus.init));
  }
}
