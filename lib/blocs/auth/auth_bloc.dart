import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
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
    on<AuthLogout>(onLogout);
    on<AuthToggleAgreeToEULA>(onToggleAgreeToEULA);
    on<AuthFlag>(onFlag);
    add(AuthInitialize());
  }

  final AuthRepository _authRepository;

  Future<void> onInitialize(
      AuthInitialize event, Emitter<AuthState> emit) async {
    await _authRepository.loggedIn.then((loggedIn) async {
      if (loggedIn) {
        await _authRepository.username.then((username) {
          emit(state.copyWith(
            isLoggedIn: true,
            username: username,
          ));
        });
      } else {
        emit(state.copyWith(
          isLoggedIn: false,
          username: '',
        ));
      }
    });
  }

  Future<void> onToggleAgreeToEULA(
      AuthToggleAgreeToEULA event, Emitter<AuthState> emit) async {
    emit(state.copyWith(agreedToEULA: !state.agreedToEULA));
  }

  Future<void> onFlag(AuthFlag event, Emitter<AuthState> emit) async {
    if (state.isLoggedIn) {
      final flagged = event.item.dead;
      await _authRepository.flag(id: event.item.id, flag: !flagged);
    }
  }

  Future<void> onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final successful = await _authRepository.login(
        username: event.username, password: event.password);

    if (successful) {
      emit(state.copyWith(
        username: event.username,
        isLoggedIn: true,
        status: AuthStatus.loaded,
      ));
    } else {
      emit(state.copyWith(status: AuthStatus.failure));
    }
  }

  Future<void> onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      username: '',
      isLoggedIn: false,
      agreedToEULA: false,
    ));

    await _authRepository.logout();
  }
}
