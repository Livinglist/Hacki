import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/home/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart' show ItemScreenArgs;
import 'package:material_ui/material_ui.dart';

/// Reuses the tablet panes as the window folds, unfolds, or resizes.
class AdaptiveHomeScreen extends StatefulWidget {
  const AdaptiveHomeScreen({
    required this.homeScreen,
    this.detailBuilder,
    super.key,
  });

  final Widget homeScreen;
  final Widget Function(BuildContext, ItemScreenArgs)? detailBuilder;

  @override
  State<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends State<AdaptiveHomeScreen> {
  double _windowWidth = 0;
  bool _updateScheduled = false;

  void _updateWindowWidth(double width) {
    _windowWidth = width;
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted) {
        context.read<SplitViewCubit>().updateWindowWidth(_windowWidth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool preferred = context.select<PreferenceCubit, bool>(
      (PreferenceCubit cubit) => cubit.state.isSplitViewEnabled,
    );
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            _updateWindowWidth(constraints.maxWidth);
            return TabletHomeScreen(
              homeScreen: widget.homeScreen,
              splitViewEnabled:
                  preferred &&
                  constraints.maxWidth >= SplitViewCubit.minimumSplitViewWidth,
              detailBuilder: widget.detailBuilder,
            );
          },
        ),
      ),
    );
  }
}
