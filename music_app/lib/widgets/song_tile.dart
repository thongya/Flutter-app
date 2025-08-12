// lib/widgets/song_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final int index;

  const SongTile({
    Key? key,
    required this.song,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: song.albumArt != null ? NetworkImage(song.albumArt!) : null,
        child: song.albumArt == null ? const Icon(Icons.music_note) : null,
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          song.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: song.isFavorite ? Colors.red : null,
        ),
        onPressed: () {
          audioProvider.toggleFavorite(song);
        },
      ),
      onTap: onTap,
    );
  }
}