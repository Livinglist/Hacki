import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TimeMachineDialog extends StatelessWidget {
  const TimeMachineDialog({
    required this.comment,
    required this.size,
    required this.deviceType,
    required this.widthFactor,
    super.key,
  });

  final Comment comment;
  final Size size;
  final DeviceScreenType deviceType;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimeMachineCubit>.value(
      value: TimeMachineCubit()..activateTimeMachine(comment),
      child: BlocBuilder<TimeMachineCubit, TimeMachineState>(
        builder: (BuildContext context, TimeMachineState state) {
          return Center(
            child: Material(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  Dimens.pt4,
                ),
              ),
              child: SizedBox(
                height: size.height * 0.8,
                width: size.width * widthFactor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.pt8,
                    vertical: Dimens.pt12,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const SizedBox(
                            width: Dimens.pt8,
                          ),
                          const Text('Ancestors:'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: Dimens.pt16,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            for (final Comment c
                                in state.ancestors) ...<Widget>[
                              CommentTile(
                                comment: c,
                                actionable: false,
                                fetchMode: FetchMode.eager,
                              ),
                              const Divider(
                                height: Dimens.zero,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
