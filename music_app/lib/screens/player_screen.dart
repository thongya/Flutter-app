// lib/screens/player_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/player_controls.dart';
import 'equalizer_screen.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
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
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          // This ensures we rebuild when the current song changes
          final currentSong = audioProvider.currentSong;

          // Print for debugging
          print('Building PlayerScreen with song: ${currentSong?.title}');

          if (currentSong == null) {
            return const Center(child: Text('No song selected'));
          }

          return Column(
            children: [
              _buildAlbumArt(context, currentSong),
              _buildSongInfo(context, currentSong),
              _buildProgressSlider(context, audioProvider),
              _buildPlayerControls(context),
              _buildAdditionalControls(context, audioProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefaultAlbumArt(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.music_note,
        size: 100,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context, dynamic currentSong) {
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
          child: currentSong?.albumArt != null
              ? Image.network(
            currentSong!.albumArt!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultAlbumArt(context),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildDefaultAlbumArt(context);
            },
          )
              : _buildDefaultAlbumArt(context),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, dynamic currentSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            currentSong?.title ?? 'Unknown Title',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            currentSong?.artist ?? 'Unknown Artist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentSong?.album != null && currentSong!.album.isNotEmpty)
            Text(
              currentSong.album,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context, AudioProvider audioProvider) {
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

  Widget _buildAdditionalControls(BuildContext context, AudioProvider audioProvider) {
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