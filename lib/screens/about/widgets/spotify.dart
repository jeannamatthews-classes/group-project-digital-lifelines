part of 'about_actions_section.dart';
// ignore_for_file: unused_element

extension _AboutActionsSectionSpotify on _AboutActionsSectionState {
  // UI flow for selecting Spotify import mode and optional start date filter.
  Future<void> _importSpotifyJsonFromFile() async {
    var importMode = ImportMode.mergeSkipDuplicates;
    DateTime? startFromDate;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Image.asset('assets/spotify.png', width: 28, height: 28),
                  const SizedBox(width: 12),
                  const Text('Import Spotify JSON'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<ImportMode>(
                      isExpanded: true,
                      initialValue: importMode,
                      decoration: InputDecoration(
                        labelText: 'Import mode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ImportMode.mergeSkipDuplicates,
                          child: Text('Merge & Skip Duplicates'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.mergeUpdateDuplicates,
                          child: Text('Merge & Update Existing'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.replaceAll,
                          child: Text('Overwrite Everything'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          importMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Filtering Options',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today_rounded, size: 20),
                        ),
                        title: const Text(
                          'Start from date',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          startFromDate == null
                              ? 'Import all history'
                              : _formatDateLabel(startFromDate!),
                          style: TextStyle(
                            color: startFromDate == null
                                ? Colors.grey
                                : AppColors.primary,
                            fontWeight: startFromDate == null
                                ? null
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: startFromDate ?? DateTime.now(),
                              firstDate: DateTime(2010, 1, 1),
                              lastDate: DateTime.now(),
                              helpText: 'Import entries on/after this date',
                            );
                            if (picked == null) return;
                            setDialogState(() {
                              startFromDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            });
                          },
                          child: const Text('Select'),
                        ),
                      ),
                    ),
                    if (startFromDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              startFromDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text(
                            'Remove date filter',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Choose Spotify File'),
                ),
              ],
            );
          },
        );
      },
    );

    if (proceed != true) return;

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File picker unavailable on this platform build'),
        ),
      );
      return;
    }

    if (picked == null || picked.files.isEmpty) return;

    final selected = picked.files.first;
    final jsonText = await _readPickedJsonText(selected);

    if (jsonText == null || jsonText.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is empty or unreadable')),
      );
      return;
    }

    await _runSpotifyImport(
      jsonText,
      importMode: importMode,
      startFromDate: startFromDate,
    );
  }

  // Converts Spotify payload to app schema, then delegates to generic importer.
  Future<void> _runSpotifyImport(
    String spotifyJsonText, {
    required ImportMode importMode,
    DateTime? startFromDate,
  }) async {
    final convertedPayload = _convertSpotifyToImportPayload(
      spotifyJsonText,
      startFromDate: startFromDate,
    );
    final convertedJsonText = jsonEncode(convertedPayload);
    await _runImport(convertedJsonText, importMode: importMode);
  }

  // Maps Spotify play-history JSON into a Digital Lifelines timeline payload.
  Map<String, dynamic> _convertSpotifyToImportPayload(
    String spotifyJsonText, {
    DateTime? startFromDate,
  }) {
    final decoded = jsonDecode(spotifyJsonText);

    List<dynamic> plays;
    if (decoded is List) {
      plays = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['plays'],
        decoded['streaming_history'],
        decoded['items'],
      ];
      final firstList = candidates.whereType<List>().cast<List>().firstWhere(
        (_) => true,
        orElse: () => const [],
      );
      if (firstList.isEmpty) {
        throw const FormatException(
          'Spotify JSON must be an array or contain plays/streaming_history/items list',
        );
      }
      plays = firstList;
    } else {
      throw const FormatException('Spotify JSON root must be a list or object');
    }

    final entries = <Map<String, dynamic>>[];
    final startDateEpochMs = startFromDate?.millisecondsSinceEpoch;
    for (final play in plays) {
      if (play is! Map) continue;

      final endTime = (play['endTime'] ?? '').toString().trim();
      final artistName = (play['artistName'] ?? '').toString().trim();
      final trackName = (play['trackName'] ?? '').toString().trim();
      final msPlayed = _parseMsPlayed(play['msPlayed']);

      final hasUsefulContent =
          endTime.isNotEmpty ||
          artistName.isNotEmpty ||
          trackName.isNotEmpty ||
          msPlayed > 0;
      if (!hasUsefulContent) continue;

      final createdAt = _spotifyEndTimeToEpochMs(endTime);
      if (startDateEpochMs != null && createdAt < startDateEpochMs) {
        continue;
      }

      entries.add({
        'created_at': createdAt,
        'is_favorite': false,
        'values': {
          'track': trackName,
          'artist': artistName,
          'end_time': endTime,
          'ms_played': msPlayed.toString(),
        },
      });
    }

    if (entries.isEmpty) {
      throw const FormatException(
        'No Spotify plays found. Expected items with endTime, artistName, trackName, msPlayed',
      );
    }

    return {
      'schema_version': 1,
      'app': 'Digital Lifelines',
      'type': 'spotify_import',
      'timelines': [
        {
          'name': 'Spotify Streaming History',
          'fields': [
            {'name': 'track', 'type': 'text'},
            {'name': 'artist', 'type': 'text'},
            {'name': 'end_time', 'type': 'text'},
            {'name': 'ms_played', 'type': 'number'},
          ],
          'entries': entries,
        },
      ],
    };
  }

  // Tolerant parsing for msPlayed values.
  int _parseMsPlayed(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  // Converts Spotify endTime string to epoch milliseconds.
  int _spotifyEndTimeToEpochMs(String endTime) {
    if (endTime.trim().isEmpty) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    final normalized = endTime.contains('T')
        ? endTime
        : endTime.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    return parsed?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  }

  String _formatDateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
