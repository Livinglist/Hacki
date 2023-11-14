import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPreferenceRepository extends Mock implements PreferenceRepository {}

class MockHackerNewsRepository extends Mock implements HackerNewsRepository {}

class MockSembastRepository extends Mock implements SembastRepository {}

void main() {
  final MockAuthRepository mockAuthRepository = MockAuthRepository();
  final MockPreferenceRepository mockPreferenceRepository =
      MockPreferenceRepository();
  final MockHackerNewsRepository mockHackerNewsRepository =
      MockHackerNewsRepository();
  final MockSembastRepository mockSembastRepository = MockSembastRepository();

  const int created = 0;
  const int delay = 1;
  const int karma = 2;
  const String about = 'about';
  const String id = 'id';

  const User tUser = User(
    about: about,
    created: created,
    delay: delay,
    id: id,
    karma: karma,
  );

  group(
    'AuthBloc',
    () {
      setUp(() {
        when(() => mockAuthRepository.loggedIn)
            .thenAnswer((_) => Future<bool>.value(false));
      });

      test(
        'initial state is AuthState.init',
        () {
          expect(
            AuthBloc(
              authRepository: mockAuthRepository,
              preferenceRepository: mockPreferenceRepository,
              hackerNewsRepository: mockHackerNewsRepository,
              sembastRepository: mockSembastRepository,
            ).state,
            equals(const AuthState.init()),
          );
        },
      );
    },
  );

  group('AuthAppStarted', () {
    const String username = 'username';
    const String password = 'password';
    setUp(() {
      when(() => mockAuthRepository.username)
          .thenAnswer((_) => Future<String?>.value(username));
      when(() => mockAuthRepository.password)
          .thenAnswer((_) => Future<String>.value(password));
      when(() => mockHackerNewsRepository.fetchUser(id: username))
          .thenAnswer((_) => Future<User>.value(tUser));
      when(() => mockAuthRepository.loggedIn)
          .thenAnswer((_) => Future<bool>.value(false));
    });

    blocTest<AuthBloc, AuthState>(
      'initialize',
      build: () {
        return AuthBloc(
          authRepository: mockAuthRepository,
          preferenceRepository: mockPreferenceRepository,
          hackerNewsRepository: mockHackerNewsRepository,
          sembastRepository: mockSembastRepository,
        );
      },
      expect: () => <AuthState>[
        const AuthState.init().copyWith(
          status: Status.success,
        ),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.loggedIn).called(2);
        verifyNever(() => mockAuthRepository.username);
        verifyNever(() => mockHackerNewsRepository.fetchUser(id: username));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'sign in',
      build: () {
        when(
          () => mockAuthRepository.login(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) => Future<bool>.value(true));
        return AuthBloc(
          authRepository: mockAuthRepository,
          preferenceRepository: mockPreferenceRepository,
          hackerNewsRepository: mockHackerNewsRepository,
          sembastRepository: mockSembastRepository,
        );
      },
      act: (AuthBloc bloc) => bloc
        ..add(
          AuthToggleAgreeToEULA(),
        )
        ..add(
          AuthLogin(
            username: username,
            password: password,
          ),
        ),
      expect: () => <AuthState>[
        const AuthState(
          user: User.empty(),
          isLoggedIn: false,
          status: Status.success,
          agreedToEULA: false,
        ),
        const AuthState(
          user: User.empty(),
          isLoggedIn: false,
          status: Status.success,
          agreedToEULA: true,
        ),
        const AuthState(
          user: User.empty(),
          isLoggedIn: false,
          status: Status.inProgress,
          agreedToEULA: true,
        ),
        const AuthState(
          user: tUser,
          isLoggedIn: true,
          status: Status.success,
          agreedToEULA: true,
        ),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepository.login(
            username: username,
            password: password,
          ),
        ).called(1);
        verify(() => mockHackerNewsRepository.fetchUser(id: username))
            .called(1);
      },
    );
  });
}
