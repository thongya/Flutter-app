// lib/screens/home_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/song_tile.dart';
import '../widgets/bottom_player.dart';
import '../utils/audio_scanner.dart';
import 'player_screen.dart';
import 'search_screen.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isScanning = false;
  int _scannedFiles = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _scanSongs();
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

    // Play the selected song
    audioProvider.playSong(index);

    // Use push instead of pushReplacement to avoid navigation issues
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(), // Remove the key to allow normal rebuild
      ),
    );
  }

  // Add this method to your HomeScreen or wherever you scan for songs
  Future<void> _requestPermissionsAndScan() async {
    if (Platform.isAndroid) {
      // Check Android version
      if (await Permission.storage.isDenied) {
        var status = await Permission.storage.request();

        // For Android 11+, also request manage external storage
        if (status != PermissionStatus.granted) {
          if (await Permission.manageExternalStorage.isDenied) {
            status = await Permission.manageExternalStorage.request();
          }
        }

        if (status != PermissionStatus.granted) {
          // Show dialog explaining why permission is needed
          _showPermissionDialog();
          return;
        }
      }
    }

    // Scan for songs after permission is granted
    _scanSongs();
  }

  void _showPermissionDialog() {
    // Show a dialog explaining why storage permission is needed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('This app needs storage permission to access your music files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
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
      child: Row(
        children: [
          _buildTab('Songs', 0),
          _buildTab('Recently Played', 1),
          _buildTab('Playlists', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (isSelected)
                Container(
                  height: 2,
                  width: 40,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
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

    final audioProvider = context.watch<AudioProvider>();

    switch (_currentIndex) {
      case 0:
        return _buildSongsList(audioProvider.songs);
      case 1:
        return _buildSongsList(audioProvider.recentlyPlayed);
      case 2:
        return const PlaylistScreen();
      default:
        return _buildSongsList(audioProvider.songs);
    }
  }

  Widget _buildSongsList(List<dynamic> songs) {
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