// lib/services/audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  MediaItem? _mediaItem;

  MusicAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = _mapProcessingState(playerState.processingState);

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      final state = playbackState.value;
      playbackState.add(state.copyWith(updatePosition: position));
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // Method to play a song
  Future<void> playSong(String songPath, MediaItem mediaItem) async {
    try {
      _mediaItem = mediaItem;
      this.mediaItem.add(mediaItem);

      await _player.setAudioSource(AudioSource.uri(Uri.parse(songPath)));
      await _player.play();
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Don't stop when task is removed - continue playing
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Don't stop when notification is deleted - continue playing
  }
}