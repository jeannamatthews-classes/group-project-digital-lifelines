// Models for Spotify data imports

class SpotifyStreamingHistory {
  final List<StreamEntry> entries;
  final String importName;
  final DateTime importDate;

  SpotifyStreamingHistory({
    required this.entries,
    required this.importName,
    required this.importDate,
  });

  factory SpotifyStreamingHistory.fromJson(List<dynamic> json, String fileName) {
    final entries = (json as List)
        .map((item) => StreamEntry.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
        .toList();

    return SpotifyStreamingHistory(
      entries: entries,
      importName: fileName,
      importDate: DateTime.now(),
    );
  }

  int getTotalPlaytime() {
    return entries.fold<int>(0, (sum, entry) => sum + (entry.msPlayed ?? 0));
  }

  Map<String, int> getTopArtists({int limit = 10}) {
    final artistCounts = <String, int>{};
    for (var entry in entries) {
      if (entry.artistName != null && entry.artistName!.isNotEmpty) {
        artistCounts[entry.artistName!] =
            (artistCounts[entry.artistName!] ?? 0) + 1;
      }
    }
    final sorted = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }
}

class StreamEntry {
  final String? endTime;
  final String? artistName;
  final String? trackName;
  final int? msPlayed;

  StreamEntry({
    this.endTime,
    this.artistName,
    this.trackName,
    this.msPlayed,
  });

  factory StreamEntry.fromJson(Map<String, dynamic> json) {
    return StreamEntry(
      endTime: json['endTime'] as String?,
      artistName: json['artistName'] as String?,
      trackName: json['trackName'] as String?,
      msPlayed: json['msPlayed'] as int?,
    );
  }

  String get displayName => '$trackName${artistName != null ? ' - $artistName' : ''}';

  String get durationDisplay {
    if (msPlayed == null) return 'N/A';
    final seconds = msPlayed! ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes % 60}m';
    }
    return '${minutes}m';
  }
}

class SpotifyPlaylist {
  final List<PlaylistData> playlists;
  final String importName;
  final DateTime importDate;

  SpotifyPlaylist({
    required this.playlists,
    required this.importName,
    required this.importDate,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json, String fileName) {
    final playlistsList = (json['playlists'] as List?)
            ?.map((item) => PlaylistData.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return SpotifyPlaylist(
      playlists: playlistsList,
      importName: fileName,
      importDate: DateTime.now(),
    );
  }

  int getTotalTracks() {
    return playlists.fold<int>(0, (sum, p) => sum + p.items.length);
  }
}

class PlaylistData {
  final String name;
  final String lastModifiedDate;
  final List<String> collaborators;
  final List<PlaylistTrack> items;
  final int numberOfFollowers;

  PlaylistData({
    required this.name,
    required this.lastModifiedDate,
    required this.collaborators,
    required this.items,
    required this.numberOfFollowers,
  });

  factory PlaylistData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.map((item) => PlaylistTrack.fromJson(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
            .toList() ??
        [];

    return PlaylistData(
      name: json['name'] as String? ?? 'Unknown Playlist',
      lastModifiedDate: json['lastModifiedDate'] as String? ?? 'N/A',
      collaborators: List<String>.from(json['collaborators'] as List? ?? []),
      items: itemsList,
      numberOfFollowers: json['numberOfFollowers'] as int? ?? 0,
    );
  }
}

class PlaylistTrack {
  final Track track;
  final String addedDate;

  PlaylistTrack({
    required this.track,
    required this.addedDate,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
    final trackJson = json['track'] as Map<dynamic, dynamic>? ?? {};
    final typedTrackJson = Map<String, dynamic>.from(trackJson);
    return PlaylistTrack(
      track: Track.fromJson(typedTrackJson),
      addedDate: json['addedDate'] as String? ?? 'N/A',
    );
  }
}

class Track {
  final String trackName;
  final String artistName;
  final String albumName;
  final String trackUri;

  Track({
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.trackUri,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      trackName: json['trackName'] as String? ?? 'Unknown',
      artistName: json['artistName'] as String? ?? 'Unknown',
      albumName: json['albumName'] as String? ?? 'Unknown',
      trackUri: json['trackUri'] as String? ?? '',
    );
  }

  String get displayName => '$trackName - $artistName';
}
