import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

void main() {
  final MockAuthRepository mockAuthRepository = MockAuthRepository();
  final MockPreferenceRepository mockPreferenceRepository =
      MockPreferenceRepository();
  final MockHackerNewsRepository mockHackerNewsRepository =
      MockHackerNewsRepository();
  final MockSembastRepository mockSembastRepository = MockSembastRepository();
  final MockLogger mockLogger = MockLogger();
  locator.registerSingleton<Logger>(mockLogger);

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

  group('AuthBloc', () {
    setUp(() {
      when(
        () => mockAuthRepository.loggedIn,
      ).thenAnswer((_) => Future<bool>.value(false));
    });

    test('initial state is AuthState.init', () {
      expect(
        AuthBloc(
          authRepository: mockAuthRepository,
          preferenceRepository: mockPreferenceRepository,
          hackerNewsRepository: mockHackerNewsRepository,
          sembastRepository: mockSembastRepository,
        ).state,
        equals(const AuthState.init()),
      );
    });
  });

  group('AuthAppStarted', () {
    const String username = 'username';
    const String password = 'password';
    setUp(() {
      when(
        () => mockAuthRepository.username,
      ).thenAnswer((_) => Future<String?>.value(username));
      when(
        () => mockAuthRepository.password,
      ).thenAnswer((_) => Future<String>.value(password));
      when(
        () => mockHackerNewsRepository.fetchUser(id: username),
      ).thenAnswer((_) => Future<User>.value(tUser));
      when(
        () => mockAuthRepository.loggedIn,
      ).thenAnswer((_) => Future<bool>.value(false));
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
        const AuthState.init().copyWith(status: Status.success),
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
          () =>
              mockAuthRepository.login(username: username, password: password),
        ).thenAnswer((_) => Future<bool>.value(true));
        return AuthBloc(
          authRepository: mockAuthRepository,
          preferenceRepository: mockPreferenceRepository,
          hackerNewsRepository: mockHackerNewsRepository,
          sembastRepository: mockSembastRepository,
        );
      },
      act: (AuthBloc bloc) => bloc
        ..add(AuthToggleAgreeToEULA())
        ..add(AuthLogin(username: username, password: password)),
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
          () =>
              mockAuthRepository.login(username: username, password: password),
        ).called(1);
        verify(
          () => mockHackerNewsRepository.fetchUser(id: username),
        ).called(1);
      },
    );
  });

  group('AuthLogout', () {
    const AuthState loggedInState = AuthState(
      user: tUser,
      isLoggedIn: true,
      status: Status.success,
      agreedToEULA: false,
    );

    setUp(() {
      reset(mockAuthRepository);
      reset(mockPreferenceRepository);
      reset(mockHackerNewsRepository);
      reset(mockSembastRepository);
      when(
        () => mockAuthRepository.loggedIn,
      ).thenAnswer((Invocation _) async => true);
      when(
        () => mockAuthRepository.username,
      ).thenAnswer((Invocation _) async => id);
      when(
        () => mockHackerNewsRepository.fetchUser(id: id),
      ).thenAnswer((Invocation _) async => tUser);
    });

    final List<Completer<void>> operationStarted =
        List<Completer<void>>.generate(3, (int _) => Completer<void>());
    final List<Completer<void>> operationCompleted =
        List<Completer<void>>.generate(3, (int _) => Completer<void>());

    Future<void> waitForOperation(int index) {
      operationStarted[index].complete();
      return operationCompleted[index].future;
    }

    blocTest<AuthBloc, AuthState>(
      'emits logged-out state only after logout and cleanup complete',
      build: () {
        when(
          () => mockAuthRepository.logout(),
        ).thenAnswer((Invocation _) => waitForOperation(0));
        when(
          () => mockPreferenceRepository.updateUnreadCommentsIds(any()),
        ).thenAnswer((Invocation _) => waitForOperation(1));
        when(
          () => mockSembastRepository.deleteCachedComments(),
        ).thenAnswer((Invocation _) => waitForOperation(2));
        return AuthBloc(
          authRepository: mockAuthRepository,
          preferenceRepository: mockPreferenceRepository,
          hackerNewsRepository: mockHackerNewsRepository,
          sembastRepository: mockSembastRepository,
        );
      },
      act: (AuthBloc bloc) async {
        await bloc.stream.firstWhere((AuthState state) => state.isLoggedIn);
        bloc.add(AuthLogout());
        try {
          for (int index = 0; index < operationStarted.length; index++) {
            await operationStarted[index].future;
            expect(bloc.state, loggedInState);
            operationCompleted[index].complete();
          }
          await bloc.stream.firstWhere((AuthState state) => !state.isLoggedIn);
        } finally {
          for (final Completer<void> operation in operationCompleted) {
            if (!operation.isCompleted) operation.complete();
          }
        }
      },
      expect: () => <AuthState>[
        loggedInState,
        const AuthState.init(),
      ],
      verify: (AuthBloc _) {
        verifyInOrder(<Future<void> Function()>[
          () => mockAuthRepository.logout(),
          () => mockPreferenceRepository.updateUnreadCommentsIds(<int>[]),
          () => mockSembastRepository.deleteCachedComments(),
        ]);
      },
    );

    const List<String> operationNames = <String>[
      'logout',
      'unread comments cleanup',
      'cached comments cleanup',
    ];
    for (final int failingOperation in <int>[0, 1, 2]) {
      final StateError error = StateError('Logout operation failed');

      Future<void> completeOperation(int index) async {
        if (index == failingOperation) throw error;
      }

      blocTest<AuthBloc, AuthState>(
        'does not emit logged-out state when '
        '${operationNames[failingOperation]} fails',
        build: () {
          when(
            () => mockAuthRepository.logout(),
          ).thenAnswer((Invocation _) => completeOperation(0));
          when(
            () => mockPreferenceRepository.updateUnreadCommentsIds(any()),
          ).thenAnswer((Invocation _) => completeOperation(1));
          when(
            () => mockSembastRepository.deleteCachedComments(),
          ).thenAnswer((Invocation _) => completeOperation(2));
          return AuthBloc(
            authRepository: mockAuthRepository,
            preferenceRepository: mockPreferenceRepository,
            hackerNewsRepository: mockHackerNewsRepository,
            sembastRepository: mockSembastRepository,
          );
        },
        act: (AuthBloc bloc) async {
          await bloc.stream.firstWhere((AuthState state) => state.isLoggedIn);
          bloc.add(AuthLogout());
        },
        expect: () => <AuthState>[loggedInState],
        errors: () => <Object>[error],
        verify: (AuthBloc bloc) => expect(bloc.state, loggedInState),
      );
    }
  });
}
