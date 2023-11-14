import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit({HackerNewsRepository? hackerNewsRepository})
      : _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        super(const UserState.init());

  final HackerNewsRepository _hackerNewsRepository;

  void init({required String userId}) {
    emit(state.copyWith(status: Status.inProgress));
    _hackerNewsRepository.fetchUser(id: userId).then((User? user) {
      emit(
        state.copyWith(
          user: user ?? User.emptyWithId(userId),
          status: Status.success,
        ),
      );
    }).onError((_, __) {
      emit(state.copyWith(status: Status.failure));
      return;
    });
  }
}
