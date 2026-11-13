import 'package:animations/animations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class ItemScreenTips extends StatefulWidget {
  const ItemScreenTips({super.key});

  @override
  State<ItemScreenTips> createState() => _ItemScreenTipsState();
}

class _ItemScreenTipsState extends State<ItemScreenTips> {
  late final VideoPlayerController _controller;

  static const double _videoHeightFactor = 0.6;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset(
            Constants.itemScreenTimeMachineTipsPath,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..setVolume(0)
          ..setLooping(true)
          ..initialize().then((_) {
            /// Ensure the first frame is shown after the video is initialized.
            if (mounted) {
              setState(() {});
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: Dimens.zero,
      closedColor: Palette.transparent,
      openColor: Theme.of(context).colorScheme.surface,
      onClosed: (_) async {
        if (!context.mounted) return;
        await _controller.pause();
        if (context.mounted) {
          context.read<TipsCubit>().completeTips(Tips.itemScreen);
        }
      },
      closedBuilder: (BuildContext context, void Function() action) {
        return IconButton(
          onPressed: () {
            _controller.play();
            action();
          },
          icon: const Icon(Icons.tips_and_updates_outlined),
        );
      },
      openBuilder: (BuildContext context, void Function() action) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tips')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimens.pt12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.height *
                            _videoHeightFactor,
                        child: Card(
                          elevation: Dimens.pt4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.pt6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimens.pt6),
                            child: _controller.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: VideoPlayer(_controller),
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBoxes.pt24,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.pt12,
                    ),
                    child: Text(
                      '''When you find yourself too deep in a thread, you can swipe left on a comment to see all its ancestors including the root story (or comment).''',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontSize: TextDimens.pt16,
                      ),
                    ),
                  ),
                  SizedBoxes.pt24,
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: action,
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(fontSize: TextDimens.pt16),
                        ),
                      ),
                      TextButton(
                        onPressed: action,
                        child: const Text(
                          'LGTM',
                          style: TextStyle(
                            fontSize: TextDimens.pt16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
