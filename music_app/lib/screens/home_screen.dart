// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/song_tile.dart';
import '../widgets/bottom_player.dart';
import '../utils/audio_scanner.dart';
import 'player_screen.dart';
import 'search_screen.dart';
import 'playlist_screen.dart';
import 'albums_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isScanning = false;
  int _scannedFiles = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Make sure this matches the number of tabs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    _scanSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanSongs() async {
    setState(() {
      _isScanning = true;
      _scannedFiles = 0;
      _totalFiles = 0;
    });

    try {
      final songs = await AudioScanner.scanDeviceWithProgress(
        onProgress: (scanned, total) {
          setState(() {
            _scannedFiles = scanned;
            _totalFiles = total;
          });
        },
      );

      if (mounted) {
        context.read<AudioProvider>().setSongs(songs);
        setState(() => _isScanning = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning songs: $e')),
        );
      }
    }
  }

  void _onSongTap(int index) {
    final audioProvider = context.read<AudioProvider>();
    audioProvider.playSong(index);

    // Use push instead of pushReplacement to avoid navigation issues
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Music Player',
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomPlayer(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
        tabs: const [
          Tab(text: 'Songs'),
          Tab(text: 'Recently Played'),
          Tab(text: 'Albums'),
          Tab(text: 'Playlists'),
          Tab(text: 'Favorites'), // Make sure this tab is included
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning songs... $_scannedFiles/${_totalFiles > 0 ? _totalFiles : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      physics: const AlwaysScrollableScrollPhysics(), // Enable swipe
      children: [
        _buildSongsList(context.watch<AudioProvider>().songs),
        _buildSongsList(context.watch<AudioProvider>().recentlyPlayed),
        const AlbumsScreen(),
        const PlaylistScreen(),
        _buildSongsList(context.watch<AudioProvider>().favoriteSongs), // Add Favorites tab content
      ],
    );
  }

  Widget _buildSongsList(List<Song> songs) {
    if (songs.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _scanSongs,
              child: const Text('Scan Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return SongTile(
          song: songs[index],
          onTap: () => _onSongTap(index),
          index: index,
        );
      },
    );
  }
}