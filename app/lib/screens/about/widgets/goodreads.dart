part of 'about_actions_section.dart';
// ignore_for_file: unused_element

extension _AboutActionsSectionGoodreads on _AboutActionsSectionState {
  // UI flow for selecting and importing a Goodreads JSON export file.
  Future<void> _importGoodreadsJsonFromFile() async {
    var importMode = ImportMode.mergeSkipDuplicates;
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
                children: const [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image(
                      image: AssetImage('assets/goodreads.png'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Import Goodreads JSON',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 14),
                    Text(
                      'Use Goodreads export JSON. User field is removed and rating is converted to stars.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
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
                    backgroundColor: const Color(0xFF6D4C41),
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
                  child: const Text('Choose File'),
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

    await _runGoodreadsImport(jsonText, importMode: importMode);
  }

  // Converts Goodreads payload to app schema, then delegates to generic importer.
  Future<void> _runGoodreadsImport(
    String goodreadsJsonText, {
    required ImportMode importMode,
  }) async {
    final convertedPayload = _convertGoodreadsToImportPayload(goodreadsJsonText);
    final convertedJsonText = jsonEncode(convertedPayload);
    await _runImport(convertedJsonText, importMode: importMode);
  }

  // Maps Goodreads review export JSON into a Digital Lifelines timeline payload.
  Map<String, dynamic> _convertGoodreadsToImportPayload(String goodreadsJsonText) {
    final decoded = jsonDecode(goodreadsJsonText);
    if (decoded is! List) {
      throw const FormatException('Goodreads JSON root must be a list');
    }

    final entries = <Map<String, dynamic>>[];

    for (final item in decoded) {
      if (item is! Map) continue;

      final hasBook = (item['book'] ?? '').toString().trim().isNotEmpty;
      final hasReadStatus =
          (item['read_status'] ?? '').toString().trim().isNotEmpty;
      final hasRating = item['rating'] != null;
      if (!hasBook && !hasReadStatus && !hasRating) {
        continue;
      }

      final createdAt = _parseGoodreadsDateToEpochMs(item['created_at']);
      final rating = _parseRatingValue(item['rating']);

      entries.add({
        'created_at': createdAt,
        'is_favorite': rating >= 5,
        'values': {
          'book': (item['book'] ?? '').toString(),
          'rating': _ratingToStars(rating),
          'read_status': (item['read_status'] ?? '').toString(),
          'review': (item['review'] ?? '').toString(),
          'includes_spoilers': (item['includes_spoilers'] ?? '').toString(),
          'notes': (item['notes'] ?? '').toString(),
          'updated_at': (item['updated_at'] ?? '').toString(),
        },
      });
    }

    if (entries.isEmpty) {
      throw const FormatException(
        'No Goodreads reviews found. Expected items with fields like book/read_status/rating.',
      );
    }

    return {
      'schema_version': 1,
      'app': 'Digital Lifelines',
      'type': 'goodreads_import',
      'timelines': [
        {
          'name': 'Goodreads Reviews',
          'fields': [
            {'name': 'book', 'type': 'text'},
            {'name': 'rating', 'type': 'text'},
            {'name': 'read_status', 'type': 'text'},
            {'name': 'review', 'type': 'text'},
            {'name': 'includes_spoilers', 'type': 'text'},
            {'name': 'notes', 'type': 'text'},
            {'name': 'updated_at', 'type': 'text'},
          ],
          'entries': entries,
        },
      ],
    };
  }

  // Parses ratings from int/num/string safely.
  int _parseRatingValue(dynamic rawRating) {
    if (rawRating is int) return rawRating;
    if (rawRating is num) return rawRating.toInt();
    return int.tryParse((rawRating ?? '').toString()) ?? 0;
  }

  // Stores rating as a visual 5-star string in imported values.
  String _ratingToStars(int rating) {
    final safe = rating.clamp(0, 5);
    return ('★' * safe) + ('☆' * (5 - safe));
  }

  // Parses Goodreads UTC date strings into epoch milliseconds.
  int _parseGoodreadsDateToEpochMs(dynamic rawDate) {
    final text = (rawDate ?? '').toString().trim();
    if (text.isEmpty || text == '(not provided)') {
      return DateTime.now().millisecondsSinceEpoch;
    }

    final normalized = text.replaceFirst(' UTC', 'Z').replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    return parsed?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  }
}
