// lib/models/song_model.dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int duration;
  final String? albumArt;
  final bool isFavorite; // Add this field

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.albumArt,
    this.isFavorite = false, // Default to false
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
      isFavorite: json['isFavorite'] as bool? ?? false, // Handle null
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
      'isFavorite': isFavorite,
    };
  }

  // Add a copyWith method for updating favorite status
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    int? duration,
    String? albumArt,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}