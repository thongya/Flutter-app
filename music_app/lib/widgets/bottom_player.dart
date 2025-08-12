// lib/widgets/bottom_player.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/player_screen.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    if (audioProvider.currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: audioProvider.currentSong?.albumArt != null
                  ? Image.network(
                audioProvider.currentSong!.albumArt!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.music_note),
              )
                  : const Icon(Icons.music_note),
            ),
          ),
          const SizedBox(width: 12),
          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  audioProvider.currentSong?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  audioProvider.currentSong?.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Controls
          Row(
            children: [
              IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: audioProvider.togglePlayPause,
              ),
              IconButton(
                icon: Icon(_getRepeatIcon(audioProvider.repeatMode),
                color: _getRepeatIconColor(audioProvider.repeatMode, context),

              ), onPressed: audioProvider.toggleRepeat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get the correct repeat icon
  IconData _getRepeatIcon(RepeatMode repeatMode) {
    switch (repeatMode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  // Helper method to get the correct repeat icon color
  Color _getRepeatIconColor(RepeatMode repeatMode, BuildContext context) {
    switch (repeatMode) {
      case RepeatMode.off:
        return Theme.of(context).iconTheme.color ?? Colors.grey;
      case RepeatMode.all:
      case RepeatMode.one:
        return Theme.of(context).primaryColor;
    }
  }
}