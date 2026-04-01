import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/styles/styles.dart';
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
    _controller = VideoPlayerController.asset(
      Constants.itemScreenTimeMachineTipsPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..setVolume(0)
      ..setLooping(true)
      ..initialize().then((_) {
        /// Ensure the first frame is shown after the video is initialized.
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: Dimens.zero,
      closedColor: Palette.transparent,
      openColor: Theme.of(context).colorScheme.surface,
      closedBuilder: (BuildContext context, void Function() action) {
        return IconButton(
          onPressed: action,
          icon: const Icon(
            Icons.tips_and_updates_outlined,
          ),
        );
      },
      openBuilder: (BuildContext context, void Function() action) {
        _controller.play();
        context.read<TipsCubit>().completeTips(Tips.itemScreen);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tips'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.pt12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
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
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: TextDimens.pt16,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    TextButton(
                      onPressed: action,
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: TextDimens.pt16,
                        ),
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
                SizedBoxes.pt100,
              ],
            ),
          ),
        );
      },
    );
  }
}
