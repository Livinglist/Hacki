import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocBuilderCondition<S> = bool Function(S previous, S current);
typedef BlocWidgetBuilder3<StateA, StateB, StateC> = Widget Function(
  BuildContext,
  StateA,
  StateB,
  StateC,
);

class BlocBuilder3<
    BlocA extends StateStreamable<BlocAState>,
    BlocAState,
    BlocB extends StateStreamable<BlocBState>,
    BlocBState,
    BlocC extends StateStreamable<BlocCState>,
    BlocCState> extends StatelessWidget {
  const BlocBuilder3({
    required this.builder,
    super.key,
    this.blocA,
    this.blocB,
    this.blocC,
    this.buildWhenA,
    this.buildWhenB,
    this.buildWhenC,
  });

  final BlocWidgetBuilder3<BlocAState, BlocBState, BlocCState> builder;

  final BlocA? blocA;
  final BlocB? blocB;
  final BlocC? blocC;

  final BlocBuilderCondition<BlocAState>? buildWhenA;
  final BlocBuilderCondition<BlocBState>? buildWhenB;
  final BlocBuilderCondition<BlocCState>? buildWhenC;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlocA, BlocAState>(
      bloc: blocA,
      buildWhen: buildWhenA,
      builder: (BuildContext context, BlocAState blocAState) {
        return BlocBuilder<BlocB, BlocBState>(
          bloc: blocB,
          buildWhen: buildWhenB,
          builder: (BuildContext context, BlocBState blocBState) {
            return BlocBuilder<BlocC, BlocCState>(
              bloc: blocC,
              buildWhen: buildWhenC,
              builder: (BuildContext context, BlocCState blocCState) {
                return builder(context, blocAState, blocBState, blocCState);
              },
            );
          },
        );
      },
    );
  }
}
