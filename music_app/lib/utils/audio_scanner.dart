// lib/utils/audio_scanner.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../constants/app_constants.dart';

class AudioScanner {
  static const String _CACHE_KEY = 'scanned_songs_cache';
  static const String _LAST_SCAN_KEY = 'last_scan_timestamp';
  static const Duration _CACHE_DURATION = Duration(hours: 100); // Cache for 1 hour

  static Future<List<Song>> scanDevice() async {
    List<Song> songs = [];

    // Request appropriate permissions based on Android version
    bool hasPermission = await _requestStoragePermissions();
    if (!hasPermission) {
      return songs;
    }

    // Get all possible storage directories
    List<Directory> directoriesToScan = await _getAllStorageDirectories();

    // Scan each directory
    for (var directory in directoriesToScan) {
      try {
        if (await directory.exists()) {
          await _scanDirectory(directory, songs);
        }
      } catch (e) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }

    // Remove duplicate songs based on path
    songs = _removeDuplicateSongs(songs);

    return songs;
  }

  // New method with progress tracking
  static Future<List<Song>> scanDeviceWithProgress({
    Function(int scanned, int total)? onProgress,
  }) async {
    // Check if we have recent cache
    final cachedSongs = await _getCachedSongs();
    if (cachedSongs != null) {
      final lastScan = await _getLastScanTime();
      if (DateTime.now().difference(lastScan) < _CACHE_DURATION) {
        return cachedSongs;
      }
    }

    List<Song> songs = [];

    // Request permissions
    bool hasPermission = await _requestStoragePermissions();
    if (!hasPermission) {
      return songs;
    }

    // Get storage directories
    List<Directory> directoriesToScan = await _getAllStorageDirectories();

    int totalFilesProcessed = 0;
    int totalFilesToScan = 0;

    // First pass: count total files (optional, for better progress)
    try {
      for (var directory in directoriesToScan) {
        if (await directory.exists()) {
          totalFilesToScan += await _countAudioFiles(directory);
        }
      }
    } catch (e) {
      // Continue even if counting fails
    }

    // Scan directories
    for (var directory in directoriesToScan) {
      try {
        if (await directory.exists()) {
          await _scanDirectoryWithProgress(
              directory,
              songs,
                  (scanned) {
                totalFilesProcessed += scanned;
                onProgress?.call(totalFilesProcessed, totalFilesToScan);
              }
          );
        }
      } catch (e) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }

    // Remove duplicates
    songs = _removeDuplicateSongs(songs);

    // Cache results
    await _cacheSongs(songs);

    return songs;
  }

  static Future<int> _countAudioFiles(Directory directory) async {
    int count = 0;
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          for (var ext in AppConstants.supportedFormats) {
            if (path.endsWith(ext)) {
              count++;
              break;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return count;
  }

  static Future<void> _scanDirectoryWithProgress(
      Directory directory,
      List<Song> songs,
      Function(int) onFileProcessed,
      ) async {
    int filesProcessed = 0;

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final file = entity;
          final path = file.path.toLowerCase();

          // Check if file has supported audio extension
          bool isSupported = false;
          for (var ext in AppConstants.supportedFormats) {
            if (path.endsWith(ext)) {
              isSupported = true;
              break;
            }
          }

          if (isSupported) {
            try {
              final stat = await file.stat();
              if (stat.size > 1024) { // Skip files smaller than 1KB
                final fileName = file.path.split('/').last;
                final title = fileName.contains('.')
                    ? fileName.substring(0, fileName.lastIndexOf('.'))
                    : fileName;

                // Extract directory name for album info
                final pathParts = file.path.split('/');
                final album = pathParts.length > 2
                    ? pathParts[pathParts.length - 2]
                    : 'Unknown Album';

                songs.add(Song(
                  id: file.path.hashCode.toString(),
                  title: title.isNotEmpty ? title : 'Unknown Title',
                  artist: 'Unknown Artist',
                  album: album,
                  path: file.path,
                  duration: stat.size.toInt(),
                ));
              }
            } catch (e) {
              print('Error processing file ${file.path}: $e');
            }

            filesProcessed++;
            onFileProcessed(1);
          }
        }
      }
    } catch (e) {
      if (!e.toString().contains('Permission denied')) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }
  }

  static Future<bool> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+)
      if (Platform.version.contains('30') ||
          Platform.version.contains('31') ||
          Platform.version.contains('32') ||
          Platform.version.contains('33') ||
          Platform.version.contains('34')) {

        // Request manage external storage permission
        var status = await Permission.manageExternalStorage.request();
        if (status == PermissionStatus.granted) {
          return true;
        }
      }

      // Fallback to regular storage permission
      var status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }

    return true; // For other platforms
  }
  // Replace the _getAllStorageDirectories method with this improved version:
  static Future<List<Directory>> _getAllStorageDirectories() async {
    List<Directory> directories = [];

    try {
      // 1. Primary internal storage
      directories.add(Directory('/storage/emulated/0'));

      // 2. Common music directories
      List<String> commonPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Android/media',
        '/sdcard',
        '/sdcard/Music',
        '/sdcard/Download'
      ];

      for (var path in commonPaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            directories.add(dir);
          }
        } catch (e) {
          // Ignore errors
        }
      }

      // 3. Get external storage directories using path_provider
      try {
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null) {
          for (var dir in externalDirs) {
            directories.add(dir);
            // Try to get root directory for SD card
            try {
              final parentPath = dir.path.contains('/Android')
                  ? dir.path.split('/Android')[0]
                  : dir.path;
              final parentDir = Directory(parentPath);
              if (await parentDir.exists()) {
                directories.add(parentDir);
              }
            } catch (e) {
              // Ignore errors
            }
          }
        }
      } catch (e) {
        print('Error getting external directories: $e');
      }

      // 4. Scan /storage for additional mounted storage
      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          await for (final entity in storageDir.list(followLinks: false)) {
            if (entity is Directory) {
              final dirName = entity.path.split('/').last;
              // Include directories that look like storage volumes
              if (dirName.length == 36 || // UUID format
                  dirName.startsWith('sdcard') ||
                  dirName.startsWith('extSdCard') ||
                  dirName.startsWith('external')) {
                directories.add(entity);
              }
            }
          }
        }
      } catch (e) {
        print('Error scanning /storage: $e');
      }

    } catch (e) {
      print('Error getting storage directories: $e');
    }

    // Remove duplicates and non-existent directories
    Set<String> uniquePaths = {};
    List<Directory> uniqueDirectories = [];

    for (var dir in directories) {
      if (!uniquePaths.contains(dir.path) && dir.path.length > 10) {
        try {
          if (await dir.exists()) {
            uniquePaths.add(dir.path);
            uniqueDirectories.add(dir);
          }
        } catch (e) {
          // Ignore directories we can't access
        }
      }
    }

    return uniqueDirectories;
  }

  static Future<void> _scanDirectory(
      Directory directory,
      List<Song> songs,
      ) async {
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final file = entity;
          final path = file.path.toLowerCase();

          // Check if file has supported audio extension
          bool isSupported = false;
          for (var ext in AppConstants.supportedFormats) {
            if (path.endsWith(ext)) {
              isSupported = true;
              break;
            }
          }

          if (isSupported) {
            try {
              final stat = await file.stat();
              if (stat.size > 1024) { // Skip files smaller than 1KB
                final fileName = file.path.split('/').last;
                final title = fileName.contains('.')
                    ? fileName.substring(0, fileName.lastIndexOf('.'))
                    : fileName;

                // Extract directory name for album info
                final pathParts = file.path.split('/');
                final album = pathParts.length > 2
                    ? pathParts[pathParts.length - 2]
                    : 'Unknown Album';

                songs.add(Song(
                  id: file.path.hashCode.toString(),
                  title: title.isNotEmpty ? title : 'Unknown Title',
                  artist: 'Unknown Artist',
                  album: album,
                  path: file.path,
                  duration: stat.size.toInt(),
                ));
              }
            } catch (e) {
              print('Error processing file ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      // Don't print errors for permission issues, just continue
      if (!e.toString().contains('Permission denied')) {
        print('Error scanning directory ${directory.path}: $e');
      }
    }
  }

  static List<Song> _removeDuplicateSongs(List<Song> songs) {
    Set<String> uniquePaths = {};
    List<Song> uniqueSongs = [];

    for (var song in songs) {
      if (!uniquePaths.contains(song.path)) {
        uniquePaths.add(song.path);
        uniqueSongs.add(song);
      }
    }

    return uniqueSongs;
  }

  // Caching methods
  static Future<List<Song>?> _getCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_CACHE_KEY);

      if (cachedData != null) {
        final List<dynamic> songsJson = json.decode(cachedData);
        return songsJson.map((json) => Song.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return null;
  }

  static Future<void> _cacheSongs(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = json.encode(songs.map((s) => s.toJson()).toList());
      await prefs.setString(_CACHE_KEY, songsJson);
      await prefs.setInt(_LAST_SCAN_KEY, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching songs: $e');
    }
  }

  static Future<DateTime> _getLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_LAST_SCAN_KEY) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}