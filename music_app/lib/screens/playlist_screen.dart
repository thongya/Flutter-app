// lib/screens/playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_tile.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final audioProvider = context.watch<AudioProvider>();

    return playlistProvider.playlists.isEmpty
        ? _buildEmptyState(context)
        : _buildPlaylists(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No playlists yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showCreatePlaylistDialog(context),
            child: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylists(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Playlist'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.queue_music,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length} songs'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    playlistProvider.deletePlaylist(playlist.id);
                  },
                ),
                onTap: () => _showPlaylistDetails(context, playlist),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final audioProvider = context.read<AudioProvider>();
                context.read<PlaylistProvider>().createPlaylist(
                  nameController.text,
                  audioProvider.songs,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDetails(BuildContext context, dynamic playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    playlist.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: playlist.songs.isEmpty
                  ? const Center(child: Text('No songs in playlist'))
                  : ListView.builder(
                itemCount: playlist.songs.length,
                itemBuilder: (context, index) {
                  return SongTile(
                    song: playlist.songs[index],
                    onTap: () {
                      final audioProvider = context.read<AudioProvider>();
                      final songIndex = audioProvider.songs
                          .indexOf(playlist.songs[index]);
                      audioProvider.playSong(songIndex);
                    },
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}