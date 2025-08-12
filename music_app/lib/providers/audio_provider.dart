// lib/providers/audio_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../utils/notification_service.dart';

enum RepeatMode { off, all, one }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService();
  AudioSession? _audioSession;

  List<Song> _songs = [];
  List<Song> _recentlyPlayed = [];
  List<Song> _favoriteSongs = [];
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
  bool _equalizerEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  double _bassBoost = 0.0;
  double _trebleBoost = 0.0;

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
  bool get equalizerEnabled => _equalizerEnabled;
  List<Song> get favoriteSongs => _favoriteSongs;
  RepeatMode get repeatMode => _repeatMode;
  double get bassBoost => _bassBoost;
  double get trebleBoost => _trebleBoost;

  AudioProvider() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Configure audio session
    _audioSession = await AudioSession.instance;
    await _audioSession!.configure(const AudioSessionConfiguration.music());

    // Initialize equalizer
    await _initEqualizer();

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

  Future<void> _initEqualizer() async {
    try {
      // Check if audio session is available
      if (_audioSession != null) {
        _equalizerEnabled = true;
        // Apply initial settings
        await _applyEqualizerSettings();
      } else {
        _equalizerEnabled = false;
      }
    } catch (e) {
      print("Error initializing equalizer: $e");
      _equalizerEnabled = false;
    }
    notifyListeners();
  }

  Future<void> _applyEqualizerSettings() async {
    if (!_equalizerEnabled) return;

    try {
      // Calculate overall volume adjustment based on equalizer settings
      double overallGain = 0.0;
      for (double setting in _equalizerSettings) {
        overallGain += setting;
      }
      overallGain = overallGain / _equalizerSettings.length;

      // Add bass and treble boost
      overallGain += (_bassBoost + _trebleBoost) / 40.0; // Scale down the effect

      // Apply overall gain as volume adjustment
      double adjustedVolume = _volume + (overallGain / 20.0); // Scale down the effect
      adjustedVolume = adjustedVolume.clamp(0.0, 1.0);

      // Set the adjusted volume
      await _audioPlayer.setVolume(adjustedVolume);

      // Try to set the system volume using Android's AudioManager
      try {
        // This is a simplified approach - in a real implementation you would use platform channels
        // to access the system volume. For now, we'll just adjust the player volume.
      } catch (e) {
        print("Error setting system volume: $e");
      }
    } catch (e) {
      print("Error applying equalizer settings: $e");
    }
  }

  // Method to load favorites from storage
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favoriteSongs') ?? [];

    // Update favorite status in songs list
    _songs = _songs.map((song) {
      return song.copyWith(isFavorite: favoriteIds.contains(song.id));
    }).toList();

    // Create favorite songs list
    _favoriteSongs = _songs.where((song) => song.isFavorite).toList();
    notifyListeners();
  }

  // Method to save favorites to storage
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = _favoriteSongs.map((song) => song.id).toList();
    await prefs.setStringList('favoriteSongs', favoriteIds);
  }

  // Method to toggle favorite status
  Future<void> toggleFavorite(Song song) async {
    final index = _songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      // Update the song in the songs list
      _songs[index] = _songs[index].copyWith(isFavorite: !_songs[index].isFavorite);

      // Update favorite songs list
      if (_songs[index].isFavorite) {
        _favoriteSongs.add(_songs[index]);
      } else {
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      }

      // Save to storage
      await _saveFavorites();
      notifyListeners();
    }
  }

  void setSongs(List<Song> songs) {
    _songs = songs;
    _loadFavorites();
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

          // Re-initialize equalizer after setting new audio source
          await _initEqualizer();
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
    if (_repeatMode == RepeatMode.one) {
      // If repeat one is enabled, just restart the current song
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else if (_isShuffle) {
      final randomIndex = Random().nextInt(_songs.length);
      await playSong(randomIndex);
    } else {
      final nextIndex = (_currentIndex + 1) % _songs.length;
      await playSong(nextIndex);
    }
  }

  Future<void> playPrevious() async {
    if (_repeatMode == RepeatMode.one) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      final previousIndex = (_currentIndex - 1) % _songs.length;
      if (previousIndex < 0) {
        await playSong(_songs.length - 1);
      } else {
        await playSong(previousIndex);
      }
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
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
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

  // Updated equalizer methods
  Future<void> setEqualizerSettings(List<double> settings) async {
    _equalizerSettings = settings;
    await _applyEqualizerSettings();
    notifyListeners();
  }

  Future<void> setBassBoost(double boost) async {
    _bassBoost = boost.clamp(0.0, 1.0);
    await _applyEqualizerSettings();
    notifyListeners();
  }

  Future<void> setTrebleBoost(double boost) async {
    _trebleBoost = boost.clamp(0.0, 1.0);
    await _applyEqualizerSettings();
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