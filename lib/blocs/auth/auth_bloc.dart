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
    PreferenceRepository? storageRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
  })  : _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(AuthState.init()) {
    on<AuthInitialize>(onInitialize);
    on<AuthLogin>(onLogin);
    on<AuthLogout>(onLogout);
    on<AuthToggleAgreeToEULA>(onToggleAgreeToEULA);
    on<AuthFlag>(onFlag);
    add(AuthInitialize());
  }

  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;
  final StoriesRepository _storiesRepository;
  final SembastRepository _sembastRepository;

  Future<void> onInitialize(
    AuthInitialize event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.loggedIn.then((bool loggedIn) async {
      if (loggedIn) {
        final String? username = await _authRepository.username;
        final User user =
            await _storiesRepository.fetchUserBy(userId: username!);

        emit(
          state.copyWith(
            isLoggedIn: true,
            user: user,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.loaded,
            isLoggedIn: false,
          ),
        );
      }
    });
  }

  Future<void> onToggleAgreeToEULA(
    AuthToggleAgreeToEULA event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(agreedToEULA: !state.agreedToEULA));
  }

  Future<void> onFlag(AuthFlag event, Emitter<AuthState> emit) async {
    if (state.isLoggedIn) {
      final bool flagged = event.item.dead;
      await _authRepository.flag(id: event.item.id, flag: !flagged);
    }
  }

  Future<void> onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final bool successful = await _authRepository.login(
      username: event.username,
      password: event.password,
    );

    if (successful) {
      final User user =
          await _storiesRepository.fetchUserBy(userId: event.username);
      emit(
        state.copyWith(
          user: user,
          isLoggedIn: true,
          status: AuthStatus.loaded,
        ),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.failure));
    }
  }

  Future<void> onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        user: User.empty(),
        isLoggedIn: false,
        agreedToEULA: false,
      ),
    );

    await _authRepository.logout();
    await _preferenceRepository.updateUnreadCommentsIds(<int>[]);
    await _sembastRepository.deleteAll();
  }
}
