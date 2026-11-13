import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Replaces the native video texture while preserving the real tips widget.
/// Actual decoded video frames need device integration tests.
class GoldenVideoPlatform extends VideoPlayerPlatform {
  int _nextId = 0;

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      ++_nextId;
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream<VideoEvent>.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 30),
      size: const Size(360, 640),
    ),
  );
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(
    color: Color(0xFF242424),
    child: Center(child: Icon(Icons.play_circle_outline, color: Colors.white)),
  );
}

Future<void> installGoldenVideoPlatform() async {
  final VideoPlayerPlatform previous = VideoPlayerPlatform.instance;
  VideoPlayerPlatform.instance = GoldenVideoPlatform();
  addTearDown(() => VideoPlayerPlatform.instance = previous);
}
