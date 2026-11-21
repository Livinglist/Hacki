import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/custom_app_bar.dart';
import 'package:hacki/screens/item/widgets/pin_icon_button.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockPinCubit extends MockCubit<PinState> implements PinCubit {}

class _MockFavCubit extends MockCubit<FavState> implements FavCubit {}

class _MockTipsCubit extends MockCubit<TipsState> implements TipsCubit {}

final Comment _comment = Comment.fromJson(const <String, dynamic>{
  'id': 123,
  'type': 'comment',
  'by': 'alice',
  'text': 'A thread worth keeping',
});

void main() {
  late _MockPinCubit pinCubit;

  setUp(() {
    pinCubit = _MockPinCubit();
    when(() => pinCubit.state).thenReturn(PinState.init());
    HapticFeedbackUtils.enabled = false;
  });

  tearDown(() {
    HapticFeedbackUtils.enabled = true;
  });

  testWidgets('pins and unpins a comment thread with visible feedback', (
    WidgetTester tester,
  ) async {
    final StreamController<PinState> pins =
        StreamController<PinState>.broadcast(sync: true);
    addTearDown(pins.close);
    whenListen(pinCubit, pins.stream, initialState: PinState.init());
    when(
      () => pinCubit.pinItem(_comment, onDone: any(named: 'onDone')),
    ).thenAnswer((Invocation invocation) {
      pins.add(
        PinState.init().copyWith(
          pinnedItemsIds: <int>[_comment.id],
          pinnedItems: <Item>[_comment],
        ),
      );
      (invocation.namedArguments[#onDone] as VoidCallback?)?.call();
    });
    when(
      () => pinCubit.unpinItem(_comment, onDone: any(named: 'onDone')),
    ).thenAnswer((Invocation invocation) {
      pins.add(PinState.init());
      (invocation.namedArguments[#onDone] as VoidCallback?)?.call();
    });

    await tester.pumpWidget(
      BlocProvider<PinCubit>.value(
        value: pinCubit,
        child: FeatureDiscovery(
          child: MaterialApp(
            home: Scaffold(body: PinIconButton(item: _comment)),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.text('Added to Pins.'), findsOneWidget);
    verify(
      () => pinCubit.pinItem(_comment, onDone: any(named: 'onDone')),
    ).called(1);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.text('Removed from Pins.'), findsOneWidget);
    verify(
      () => pinCubit.unpinItem(_comment, onDone: any(named: 'onDone')),
    ).called(1);
  });

  testWidgets('shows the pin button on a comment thread app bar', (
    WidgetTester tester,
  ) async {
    final _MockFavCubit favCubit = _MockFavCubit();
    when(() => favCubit.state).thenReturn(FavState.init());
    final _MockTipsCubit tipsCubit = _MockTipsCubit();
    when(
      () => tipsCubit.state,
    ).thenReturn(const TipsState(completedTips: <Tips>{Tips.itemScreen}));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PinCubit>.value(value: pinCubit),
          BlocProvider<FavCubit>.value(value: favCubit),
          BlocProvider<TipsCubit>.value(value: tipsCubit),
        ],
        child: FeatureDiscovery(
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                appBar: CustomAppBar(
                  context: context,
                  item: _comment,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onFontSizeTap: () {},
                  fontSizeIconButtonKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PinIconButton), findsOneWidget);
    expect(
      tester.widget<PinIconButton>(find.byType(PinIconButton)).item,
      _comment,
    );
    expect(tester.takeException(), isNull);
  });
}
