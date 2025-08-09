// lib/screens/player_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/player_controls.dart';
import 'equalizer_screen.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.equalizer),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EqualizerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAlbumArt(context),
          _buildSongInfo(context),
          _buildProgressSlider(context),
          _buildPlayerControls(context),
          _buildAdditionalControls(context),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    return Container(
      height: 300,
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: song?.albumArt != null
              ? Image.network(
            song!.albumArt!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultAlbumArt(context),
          )
              : _buildDefaultAlbumArt(context),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt(BuildContext context) {
    return Icon(
      Icons.music_note,
      size: 100,
      color: Theme.of(context).primaryColor,
    );
  }

  Widget _buildSongInfo(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            song?.title ?? 'Unknown Title',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song?.artist ?? 'Unknown Artist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (song?.album != null && song!.album.isNotEmpty)
            Text(
              song.album,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Theme.of(context).dividerColor,
              thumbColor: Theme.of(context).primaryColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: audioProvider.currentPosition.inMilliseconds.toDouble(),
              min: 0,
              max: audioProvider.totalDuration.inMilliseconds.toDouble(),
              onChanged: (value) {
                audioProvider.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioProvider.currentPosition),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatDuration(audioProvider.totalDuration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return const PlayerControls();
  }

  Widget _buildAdditionalControls(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: audioProvider.isShuffle
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            onPressed: audioProvider.toggleShuffle,
          ),
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: audioProvider.isRepeat
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            onPressed: audioProvider.toggleRepeat,
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () => _showSleepTimerDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => _showVolumeDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sleep Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                audioProvider.setSleepTimer(10);
                Navigator.pop(context);
              },
              child: const Text('10 minutes'),
            ),
            ElevatedButton(
              onPressed: () {
                audioProvider.setSleepTimer(30);
                Navigator.pop(context);
              },
              child: const Text('30 minutes'),
            ),
            ElevatedButton(
              onPressed: () {
                audioProvider.setSleepTimer(60);
                Navigator.pop(context);
              },
              child: const Text('1 hour'),
            ),
            ElevatedButton(
              onPressed: () {
                audioProvider.cancelSleepTimer();
                Navigator.pop(context);
              },
              child: const Text('Cancel Timer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeDialog(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume'),
        content: Slider(
          value: audioProvider.volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: '${(audioProvider.volume * 100).round()}%',
          onChanged: (value) {
            audioProvider.setVolume(value);
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}