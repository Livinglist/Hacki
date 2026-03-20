import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocWidgetBuilder2<StateA, StateB> = Widget Function(
  BuildContext,
  StateA,
  StateB,
);

class BlocBuilder2<
    BlocA extends StateStreamable<BlocAState>,
    BlocAState,
    BlocB extends StateStreamable<BlocBState>,
    BlocBState> extends StatelessWidget {
  const BlocBuilder2({
    required this.builder,
    super.key,
    this.blocA,
    this.blocB,
    this.buildWhenA,
    this.buildWhenB,
  });

  final BlocWidgetBuilder2<BlocAState, BlocBState> builder;

  final BlocA? blocA;
  final BlocB? blocB;

  final BlocBuilderCondition<BlocAState>? buildWhenA;
  final BlocBuilderCondition<BlocBState>? buildWhenB;

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
            return builder(
              context,
              blocAState,
              blocBState,
            );
          },
        );
      },
    );
  }
}
