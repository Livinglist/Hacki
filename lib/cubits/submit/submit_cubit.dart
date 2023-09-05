import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/post_repository.dart';

part 'submit_state.dart';

class SubmitCubit extends Cubit<SubmitState> {
  SubmitCubit({PostRepository? postRepository})
      : _postRepository = postRepository ?? locator.get<PostRepository>(),
        super(const SubmitState.init());

  final PostRepository _postRepository;

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title));
  }

  void onUrlChanged(String url) {
    emit(state.copyWith(url: url));
  }

  void onTextChanged(String text) {
    emit(state.copyWith(text: text));
  }

  void onSubmitTapped() {
    emit(state.copyWith(status: Status.inProgress));

    if (state.title?.isNotEmpty ?? false) {
      _postRepository
          .submit(
        title: state.title!,
        url: state.url,
        text: state.text,
      )
          .then((bool successful) {
        emit(state.copyWith(status: Status.success));
      }).onError((Object? error, StackTrace stackTrace) {
        emit(state.copyWith(status: Status.failure));
      });
    }
  }
}
