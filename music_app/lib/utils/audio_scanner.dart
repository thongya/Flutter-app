// lib/utils/audio_scanner.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import '../constants/app_constants.dart';

class AudioScanner {
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

  static Future<List<Directory>> _getAllStorageDirectories() async {
    List<Directory> directories = [];

    try {
      // 1. Internal storage directories
      directories.add(Directory('/storage/emulated/0'));
      directories.add(Directory('/storage/emulated/0/Music'));
      directories.add(Directory('/storage/emulated/0/Download'));
      directories.add(Directory('/storage/emulated/0/Audio'));
      directories.add(Directory('/storage/emulated/0/Documents'));
      directories.add(Directory('/storage/emulated/0/Android/media'));

      // 2. Get external storage directories using path_provider
      final externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null) {
        for (var dir in externalDirs) {
          directories.add(dir);
          // Add parent directory (SD card root)
          try {
            final parentPath = dir.path.split('/Android')[0];
            directories.add(Directory(parentPath));
          } catch (e) {
            print('Error getting parent directory: $e');
          }
        }
      }

      // 3. Common SD card paths
      List<String> commonSdCardPaths = [
        '/storage/sdcard0',
        '/storage/sdcard1',
        '/storage/extSdCard',
        '/storage/external_SD',
        '/mnt/sdcard',
        '/mnt/external_sd',
        '/sdcard',
        '/sdcard0',
        '/sdcard1',
        '/external_sd',
        '/extSdCard'
      ];

      for (var path in commonSdCardPaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            directories.add(dir);
          }
        } catch (e) {
          // Ignore errors for non-existent paths
        }
      }

      // 4. Scan /storage directory for any mounted storage
      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          await for (final entity in storageDir.list()) {
            if (entity is Directory) {
              final dirName = entity.path.split('/').last;
              // Skip emulated and self directories
              if (!dirName.contains('emulated') &&
                  !dirName.contains('self') &&
                  dirName.length > 2) {
                directories.add(entity);
              }
            }
          }
        }
      } catch (e) {
        print('Error scanning /storage directory: $e');
      }

    } catch (e) {
      print('Error getting storage directories: $e');
    }

    // Remove duplicates
    Set<String> uniquePaths = {};
    List<Directory> uniqueDirectories = [];

    for (var dir in directories) {
      if (!uniquePaths.contains(dir.path)) {
        uniquePaths.add(dir.path);
        uniqueDirectories.add(dir);
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
}