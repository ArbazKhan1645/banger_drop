import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Listen to player state and update playback state
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      playbackState.add(
        PlaybackState(
          controls: [MediaControl.pause, MediaControl.play, MediaControl.stop],
          systemActions: const {
            MediaAction.play,
            MediaAction.pause,
            MediaAction.stop,
          },
          playing: playing,
          processingState:
              {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[processingState]!,
          updateTime: DateTime.now(),
        ),
      );
    });
  }

  Future<void> playAudio(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();
}
