import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    AuthRepository? authRepository,
  })  : _authRepository = authRepository ?? locator.get<AuthRepository>(),
        super(const AuthState.init()) {
    on<AuthInitialize>(onInitialize);
    on<AuthLogin>(onLogin);
    add(AuthInitialize());
  }

  final AuthRepository _authRepository;

  Future<void> onInitialize(
      AuthInitialize event, Emitter<AuthState> emit) async {
    await _authRepository.loggedIn.then((loggedIn) {
      if (loggedIn) {
        emit(state.copyWith(isLoggedIn: true));
      }
    });
  }

  Future<void> onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final successful = await _authRepository.login(
        username: event.username, password: event.password);

    if (successful) {
      emit(state.copyWith(isLoggedIn: true, status: AuthStatus.loaded));
    } else {
      emit(state.copyWith(status: AuthStatus.failure));
    }
  }
}
