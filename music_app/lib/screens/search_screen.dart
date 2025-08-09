// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/custom_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSongs);
  }

  void _filterSongs() {
    final audioProvider = context.read<AudioProvider>();
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredSongs = []);
    } else {
      final filtered = audioProvider.songs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query);
      }).toList();

      setState(() => _filteredSongs = filtered);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSongs);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: ' Search songs, artists, albums...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text('Start typing to search'),
      );
    }

    if (_filteredSongs.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        return SongTile(
          song: _filteredSongs[index],
          onTap: () {
            final audioProvider = context.read<AudioProvider>();
            final songIndex = audioProvider.songs.indexOf(_filteredSongs[index]);
            audioProvider.playSong(songIndex);
          },
          index: index,
        );
      },
    );
  }
}