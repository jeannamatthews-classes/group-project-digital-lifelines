import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/models/spotify_models.dart';

class SpotifyFileService {
  static Future<SpotifyImport?> parseJsonFile(File file) async {
    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      final fileName = file.path.split(Platform.pathSeparator).last;

      // Check if it's a streaming history (List)
      if (json is List) {
        final history = SpotifyStreamingHistory.fromJson(json, fileName);
        return SpotifyImport(
          type: ImportType.streamingHistory,
          data: history,
          fileName: fileName,
        );
      }

      // Check if it's a playlist (Map with 'playlists' key)
      if (json is Map<dynamic, dynamic> && json.containsKey('playlists')) {
        final typedJson = Map<String, dynamic>.from(json);
        final playlist = SpotifyPlaylist.fromJson(typedJson, fileName);
        return SpotifyImport(
          type: ImportType.playlist,
          data: playlist,
          fileName: fileName,
        );
      }

      return null;
    } catch (e) {
      print('Error parsing file: $e');
      return null;
    }
  }
}

enum ImportType {
  streamingHistory,
  playlist,
}

class SpotifyImport {
  final ImportType type;
  final dynamic data; // Can be SpotifyStreamingHistory or SpotifyPlaylist
  final String fileName;
  final DateTime importedAt;

  SpotifyImport({
    required this.type,
    required this.data,
    required this.fileName,
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();

  String get displayName {
    if (type == ImportType.streamingHistory) {
      return 'History: ${fileName.replaceAll('.json', '')}';
    }
    return 'Playlists: ${fileName.replaceAll('.json', '')}';
  }

  String get tabLabel {
    if (type == ImportType.streamingHistory) {
      return 'History ${importedAt.month}/${importedAt.day}';
    }
    return 'Playlists ${importedAt.month}/${importedAt.day}';
  }
}
