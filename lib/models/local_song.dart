// lib/models/song_model.dart
class SongModel {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final int duration;
  final String album;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.duration,
    required this.album,
  });
}