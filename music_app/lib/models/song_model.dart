// lib/models/song_model.dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int duration;
  final String? albumArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.albumArt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      path: json['path'] as String,
      duration: json['duration'] as int,
      albumArt: json['albumArt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration,
      'albumArt': albumArt,
    };
  }
}