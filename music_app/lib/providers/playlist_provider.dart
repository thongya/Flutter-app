// lib/providers/playlist_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistProvider with ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> createPlaylist(String name, List<Song> songs) async {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: songs,
      createdAt: DateTime.now(),
    );

    _playlists.add(newPlaylist);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((playlist) => playlist.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _playlists.firstWhere(
          (p) => p.id == playlistId,
      orElse: () => throw Exception('Playlist not found'),
    );

    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _playlists.firstWhere(
          (p) => p.id == playlistId,
      orElse: () => throw Exception('Playlist not found'),
    );

    playlist.songs.removeWhere((s) => s.id == songId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('playlists') ?? '[]';
    final List<dynamic> playlistsData = json.decode(playlistsJson);

    _playlists = playlistsData
        .map((data) => Playlist.fromJson(data as Map<String, dynamic>))
        .toList();

    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = json.encode(
      _playlists.map((playlist) => playlist.toJson()).toList(),
    );
    await prefs.setString('playlists', playlistsJson);
  }
}