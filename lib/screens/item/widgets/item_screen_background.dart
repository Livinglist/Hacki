import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';

class ItemScreenBackground extends StatefulWidget {
  const ItemScreenBackground({
    required this.indentPadding,
    required this.indentLineWidth,
    this.shouldShowRootLevelLine = true,
    super.key,
  });

  final double indentPadding;
  final double indentLineWidth;

  /// Root level indent line should be hidden on tablet.
  final bool shouldShowRootLevelLine;

  @override
  State<ItemScreenBackground> createState() => _ItemScreenBackgroundState();
}

class _ItemScreenBackgroundState extends State<ItemScreenBackground> {
  int _shineIndex = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEyeCandyEnabled =
        context.read<PreferenceCubit>().state.isEyeCandyEnabled;
    return BlocConsumer<CommentsCubit, CommentsState>(
      listenWhen: (CommentsState previous, CommentsState current) =>
          previous.status != current.status,
      listener: (BuildContext context, CommentsState state) {
        if (state.status == CommentsStatus.allLoaded && isEyeCandyEnabled) {
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
            setState(() {
              _shineIndex = (_shineIndex + 1) % (state.maxLevel + 1);
            });
          });
        }
      },
      buildWhen: (CommentsState previous, CommentsState current) =>
          previous.maxLevel != current.maxLevel ||
          previous.status != current.status,
      builder: (BuildContext context, CommentsState state) {
        if (state.status != CommentsStatus.allLoaded) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: <Widget>[
            if (widget.shouldShowRootLevelLine && state.comments.isNotEmpty)
              Padding(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: widget.indentLineWidth,
                  child: isEyeCandyEnabled
                      ? AnimatedIndentLine(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          width: widget.indentLineWidth,
                          isShining: _shineIndex == 0,
                        )
                      : Container(
                          width: widget.indentLineWidth,
                          height: MediaQuery.of(context).size.height,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                ),
              ),
            if (state.maxLevel > 0)
              for (final int i in 1.to(
                state.maxLevel,
              ))
                Padding(
                  padding: EdgeInsets.only(
                    left: widget.indentPadding * i,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: widget.indentLineWidth,
                    child: isEyeCandyEnabled
                        ? AnimatedIndentLine(
                            color: ColorUtil.getRainbowColor(
                              i,
                              Theme.of(context).canvasColor,
                            ).$1,
                            width: widget.indentLineWidth,
                            isShining: _shineIndex == i,
                          )
                        : Container(
                            width: widget.indentLineWidth,
                            height: MediaQuery.of(context).size.height,
                            color: ColorUtil.getRainbowColor(
                              i,
                              Theme.of(context).canvasColor,
                            ).$1,
                          ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
