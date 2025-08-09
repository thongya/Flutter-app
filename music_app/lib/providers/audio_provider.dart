// lib/providers/audio_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song_model.dart';
import '../utils/notification_service.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService();

  List<Song> _songs = [];
  List<Song> _recentlyPlayed = [];
  Song? _currentSong;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSleepTimerActive = false;
  Timer? _sleepTimer;
  double _volume = 1.0;
  List<double> _equalizerSettings = List.filled(10, 0.0);
  bool _playlistNeedsUpdate = true;

  // Getters
  List<Song> get songs => _songs;
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isSleepTimerActive => _isSleepTimerActive;
  double get volume => _volume;
  List<double> get equalizerSettings => _equalizerSettings;
  List<Song> get recentlyPlayed => _recentlyPlayed;

  AudioProvider() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to player events
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index < _songs.length) {
        _currentIndex = index;
        _currentSong = _songs[index];
        _addToRecentlyPlayed(_currentSong!);
        _notificationService.showNotification(_currentSong!);
        notifyListeners();
      }
    });
  }

  void setSongs(List<Song> songs) {
    _songs = songs;
    _playlistNeedsUpdate = true;
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    print('playSong called with index: $index');
    if (index >= 0 && index < _songs.length) {
      print('Playing song: ${_songs[index].title}');

      try {
        // Update playlist if needed
        if (_playlistNeedsUpdate) {
          final playlist = ConcatenatingAudioSource(
            children: _songs.map((song) => AudioSource.uri(Uri.parse(song.path))).toList(),
          );
          await _audioPlayer.setAudioSource(
            playlist,
            initialIndex: index,
            initialPosition: Duration.zero,
          );
          _playlistNeedsUpdate = false;
        } else {
          // If playlist is already set, just seek to the song
          await _audioPlayer.seek(Duration.zero, index: index);
        }

        await _audioPlayer.play();
        _addToRecentlyPlayed(_songs[index]);
        notifyListeners();
        print('Successfully started playing: ${_songs[index].title}');
      } catch (e) {
        print('Error playing song at index $index: $e');
      }
    } else {
      print('Invalid index: $index, songs length: ${_songs.length}');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_currentSong != null) {
        await _audioPlayer.play();
      } else if (_songs.isNotEmpty) {
        // If no song is currently playing, start with the first song
        await playSong(0);
      }
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_isShuffle) {
      final randomIndex = Random().nextInt(_songs.length);
      await playSong(randomIndex);
    } else {
      final nextIndex = (_currentIndex + 1) % _songs.length;
      await playSong(nextIndex);
    }
  }

  Future<void> playPrevious() async {
    final previousIndex = (_currentIndex - 1) % _songs.length;
    if (previousIndex < 0) {
      await playSong(_songs.length - 1);
    } else {
      await playSong(previousIndex);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    _audioPlayer.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _isSleepTimerActive = true;
    _sleepTimer?.cancel();
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _audioPlayer.stop();
      _isSleepTimerActive = false;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _isSleepTimerActive = false;
    notifyListeners();
  }

  void setEqualizerSettings(List<double> settings) {
    _equalizerSettings = settings;
    notifyListeners();
  }

  void _addToRecentlyPlayed(Song song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed.removeLast();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

void handleAppLifecycle() {
  // Don't stop playback when app goes to background
  // The audio service will handle background playback
}