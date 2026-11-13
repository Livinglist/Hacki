import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

const Key goldenKey = Key('golden');

PreferenceState slidePreferenceState({
  SlideAction leading = SlideAction.upvote,
  SlideAction secondary = SlideAction.reply,
  SlideAction trailing = SlideAction.timeMachine,
  bool swapped = false,
}) {
  return PreferenceState.init()
      .copyWithPreference(LeadingActionPreference(val: leading.index))
      .copyWithPreference(SecondaryActionPreference(val: secondary.index))
      .copyWithPreference(TrailingActionPreference(val: trailing.index))
      .copyWithPreference(SwappedSlidePanesPreference(val: swapped));
}

extension GoldenWidgetTester on WidgetTester {
  /// Pumps [child] inside the app theme with the blocs the slide action
  /// widgets read, on a surface of the given [size].
  Future<void> pumpGolden(
    Widget child, {
    required PreferenceState preferenceState,
    required Size size,
    String username = '',
    Brightness brightness = Brightness.light,
  }) async {
    await binding.setSurfaceSize(size);
    addTearDown(() => binding.setSurfaceSize(null));

    final MockPreferenceCubit preferenceCubit = MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(preferenceState);

    final MockAuthBloc authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthState.init().copyWith(user: User.emptyWithId(username)),
    );

    final bool isDarkModeEnabled = brightness == Brightness.dark;

    await pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(
            ColorScheme.fromSeed(
              brightness: brightness,
              seedColor: Palette.deepOrange,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            Font.robotoSlab,
            isDarkModeEnabled: isDarkModeEnabled,
            isTrueDarkModeEnabled: false,
          ),
          builder: (BuildContext context, Widget? child) =>
              RepaintBoundary(key: goldenKey, child: child),
          home: Scaffold(body: child),
        ),
      ),
    );
    await pumpAndSettle();
  }
}
