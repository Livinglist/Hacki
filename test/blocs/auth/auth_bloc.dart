import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:mocktail/mocktail.dart';

part 'auth_event.dart';
part 'auth_state.dart';

//    AuthRepository? authRepository,
//     PreferenceRepository? preferenceRepository,
//     StoriesRepository? storiesRepository,
//     SembastRepository? sembastRepository,

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPreferenceRepository extends Mock implements PreferenceRepository {}

class MockStoriesRepository extends Mock implements StoriesRepository {}

class MockSembastRepository extends Mock implements SembastRepository {}

void main() {
  final MockAuthRepository mockAuthRepository = MockAuthRepository();
  final MockPreferenceRepository mockPreferenceRepository =
      MockPreferenceRepository();
  final MockStoriesRepository mockStoriesRepository = MockStoriesRepository();
  final MockSembastRepository mockSembastRepository = MockSembastRepository();

  const int created = 0, delay = 1, karma = 2;
  const String about = 'about', id = 'id';

  final User tUser = User(
    about: about,
    created: created,
    delay: delay,
    id: id,
    karma: karma,
  );

  group(
    'AuthBloc',
    () {
      test(
        'initial state is AuthState.init',
        () {
          expect(
            AuthBloc(
              authRepository: mockAuthRepository,
              preferenceRepository: mockPreferenceRepository,
              storiesRepository: mockStoriesRepository,
              sembastRepository: mockSembastRepository,
            ).state,
            equals(AuthState.init()),
          );
        },
      );
    },
  );

  group('AuthAppStarted', () {
    const String username = 'username', password = 'password';
    setUp(() {
      when(() => mockAuthRepository.username)
          .thenAnswer((_) => Future<String?>.value(username));
      when(() => mockAuthRepository.loggedIn)
          .thenAnswer((_) => Future<bool>.value(true));
      when(() => mockAuthRepository.password)
          .thenAnswer((_) => Future<String>.value(password));
    });

    blocTest();

    // blocTest<AuthBloc, AuthState>(
    //   'emits [AuthState.anonymous, AuthState.unauthenticated]',
    //   build: () => AuthBloc(
    //     authRepository: mockAuthRepository,
    //     userRepository: mockUserRepository,
    //     personalizationQuizRepository: mockPersonalizationQuizRepository,
    //     analyticsService: mockAnalyticsService,
    //     sharedPreferencesService: mockSharedPreferencesService,
    //   ),
    //   act: (bloc) => bloc.add(AuthAppStarted()),
    //   expect: () => [
    //     AuthState.anonymous(
    //       user: tUser,
    //       hasTakenPersonalizationQuiz: false,
    //     ),
    //     const AuthState.unauthenticated(),
    //   ],
    //   verify: (_) {
    //     verify(() => mockAuthRepository.getCurrentUser()).called(1);
    //     verify(() => mockAuthRepository.logInAnonymously()).called(1);
    //     verify(() => mockUserRepository.syncPushTokens()).called(1);
    //     verify(() => mockPersonalizationQuizRepository
    //         .hasTakenPersonalizationQuiz(userId: tUser.user.id)).called(1);
    //     verify(() => mockAuthRepository.isAnonymous()).called(1);
    //   },
    // );
  });
}
