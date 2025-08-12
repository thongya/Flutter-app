// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:music_app/screens/player_screen.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    if (audioProvider.favoriteSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite songs yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon to add songs to favorites',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: audioProvider.favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = audioProvider.favoriteSongs[index];
        return SongTile(
          song: song,
          onTap: () {
            final globalIndex = audioProvider.songs.indexOf(song);
            if (globalIndex != -1) {
              audioProvider.playSong(globalIndex);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerScreen(),
                ),
              );
            }
          },
          index: index,
        );
      },
    );
  }
}