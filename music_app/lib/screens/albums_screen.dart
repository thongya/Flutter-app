// lib/screens/albums_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_tile.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    // Group songs by album
    Map<String, List<dynamic>> albums = {};
    for (var song in audioProvider.songs) {
      if (!albums.containsKey(song.album)) {
        albums[song.album] = [];
      }
      albums[song.album]!.add(song);
    }

    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No albums found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: albums.keys.length,
      itemBuilder: (context, albumIndex) {
        final albumName = albums.keys.elementAt(albumIndex);
        final albumSongs = albums[albumName]!;

        return ExpansionTile(
          title: Text(albumName),
          subtitle: Text('${albumSongs.length} songs'),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.album,
              color: Theme.of(context).primaryColor,
            ),
          ),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: albumSongs.length,
              itemBuilder: (context, songIndex) {
                return SongTile(
                  song: albumSongs[songIndex],
                  onTap: () {
                    final audioProvider = context.read<AudioProvider>();
                    final globalSongIndex = audioProvider.songs.indexOf(albumSongs[songIndex]);
                    audioProvider.playSong(globalSongIndex);
                  },
                  index: songIndex,
                );
              },
            ),
          ],
        );
      },
    );
  }
}