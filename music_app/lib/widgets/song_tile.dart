// lib/widgets/song_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final int index; // Add this line

  const SongTile({
    Key? key,
    required this.song,
    required this.onTap,
    required this.index, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentlyPlaying = audioProvider.currentSong?.id == song.id && audioProvider.isPlaying;

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isCurrentlyPlaying
            ? Icon(
          Icons.play_arrow,
          color: Theme.of(context).primaryColor,
          size: 24,
        )
            : Icon(
          Icons.music_note,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}