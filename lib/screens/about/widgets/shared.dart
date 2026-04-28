part of 'about_actions_section.dart';
// ignore_for_file: unused_element, invalid_use_of_protected_member

extension _AboutActionsSectionShared on _AboutActionsSectionState {
  // Example JSON users can paste to understand expected schema quickly.
  String get _importExampleJson => const JsonEncoder.withIndent('  ').convert({
    'schema_version': 1,
    'app': 'Digital Lifelines',
    'type': 'template',
    'timelines': [
      {
        'name': 'Books',
        'fields': [
          {'name': 'title', 'type': 'text'},
          {'name': 'author', 'type': 'text'},
          {'name': 'rating', 'type': 'number'},
        ],
        'entries': [
          {
            'created_at': 1710000000000,
            'is_favorite': true,
            'values': {
              'title': 'Atomic Habits',
              'author': 'James Clear',
              'rating': '5',
            },
          },
        ],
      },
    ],
  });

  // Generic dialog helper used for template/export JSON previews.
  Future<void> _showJsonOutput({
    required String title,
    required String jsonText,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: SelectableText(jsonText)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonText));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTemplateJson() async {
    final template = _dbHelper.buildTemplateJson();
    final jsonText = const JsonEncoder.withIndent('  ').convert(template);
    await _showJsonOutput(title: 'Template JSON', jsonText: jsonText);
  }

  // Saves export using platform channel on Android, with local-file fallback.
  Future<String> _saveExportFile(String jsonText, int timestamp) async {
    if (Platform.isAndroid) {
      try {
        final fileName = 'digital_lifelines_export_$timestamp.json';
        final saved = await _AboutActionsSectionState._filesChannel
            .invokeMethod<String>(
          'saveJsonToDownloads',
          {'fileName': fileName, 'content': jsonText},
        );
        if (saved != null && saved.isNotEmpty) {
          return saved;
        }
      } catch (_) {
        // Fallback below.
      }
    }

    final basePath = await getDatabasesPath();
    final fallbackDir = Directory(join(basePath, 'digitallifelines'));
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    final fallbackPath = join(
      fallbackDir.path,
      'digital_lifelines_export_$timestamp.json',
    );
    final fallbackFile = File(fallbackPath);
    await fallbackFile.writeAsString(jsonText);
    return fallbackFile.path;
  }

  // Full export flow: build payload, save file, and show user feedback actions.
  Future<void> _exportJsonToPhone() async {
    setState(() {
      _isBusy = true;
    });

    try {
      final export = await _dbHelper.exportToJson();
      final jsonText = const JsonEncoder.withIndent('  ').convert(export);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedLocation = await _saveExportFile(jsonText, timestamp);

      if (!mounted) return;
      setState(() {
        _lastExportPath = savedLocation;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            scrollable: true,
            title: const Text('Export Complete'),
            content: Text('File saved on phone:\n$savedLocation'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: savedLocation));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved path copied to clipboard'),
                    ),
                  );
                },
                child: const Text('Copy Path'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonText));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export JSON copied to clipboard'),
                    ),
                  );
                },
                child: const Text('Copy JSON'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export JSON: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  // Import flow from pasted JSON text.
  Future<void> _importJson() async {
    final controller = TextEditingController();
    var importMode = ImportMode.mergeSkipDuplicates;

    final payload = await showDialog<_ImportDialogResult>(
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
                  Icon(Icons.download_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text('Import JSON'),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        minLines: 4,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Paste your JSON here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: importMode == ImportMode.replaceAll,
                          onChanged: (value) {
                            setDialogState(() {
                              importMode = (value ?? false)
                                  ? ImportMode.replaceAll
                                  : ImportMode.mergeSkipDuplicates;
                            });
                          },
                          title: const Text('Replace existing data'),
                          subtitle: const Text(
                            'Warning: this deletes current data',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(16),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.text = _importExampleJson;
                  },
                  child: const Text('Use Example'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      _ImportDialogResult(
                        jsonText: controller.text,
                        importMode: importMode,
                      ),
                    );
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );

    if (payload == null || payload.jsonText.trim().isEmpty) {
      return;
    }

    await _runImport(payload.jsonText, importMode: payload.importMode);
  }

  // Import flow from picked JSON file.
  Future<void> _importJsonFromFile() async {
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
                children: [
                  Icon(Icons.folder_open_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text('Import From File'),
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
                    const SizedBox(height: 16),
                    Text(
                      'Choose a .json file containing your lifeline data.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
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
      await _importJsonFromPath();
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

    await _runImport(jsonText, importMode: importMode);
  }

  // Fallback import by manual path when file picker is unavailable.
  Future<void> _importJsonFromPath() async {
    final controller = TextEditingController();
    var importMode = ImportMode.mergeSkipDuplicates;
    final payload = await showDialog<_PathImportDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Import From File Path'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText:
                            '/storage/emulated/0/Download/digital_lifelines_import.json',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ImportMode>(
                      isExpanded: true,
                      initialValue: importMode,
                      decoration: const InputDecoration(
                        labelText: 'Import mode',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ImportMode.mergeSkipDuplicates,
                          child: Text('Merge and skip duplicates'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.mergeUpdateDuplicates,
                          child: Text('Merge and update duplicates'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.replaceAll,
                          child: Text('Replace all existing data'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          importMode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _PathImportDialogResult(
                      path: controller.text.trim(),
                      importMode: importMode,
                    ),
                  ),
                  child: const Text('Load'),
                ),
              ],
            );
          },
        );
      },
    );

    final path = payload?.path ?? '';
    if (path.isEmpty) return;

    try {
      final bytes = await File(path).readAsBytes();
      final jsonText = _decodeTextWithFallback(bytes);
      if (jsonText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File is empty')));
        return;
      }
      await _runImport(
        jsonText,
        importMode: payload?.importMode ?? ImportMode.mergeSkipDuplicates,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read path: $e')));
    }
  }

  // Reads bytes and decodes with robust encoding detection.
  Future<String?> _readPickedJsonText(PlatformFile selected) async {
    if (selected.path != null && selected.path!.isNotEmpty) {
      final bytes = await File(selected.path!).readAsBytes();
      return _decodeTextWithFallback(bytes);
    }

    final bytes = selected.bytes;
    if (bytes == null) {
      return null;
    }
    return _decodeTextWithFallback(bytes);
  }

  // Handles UTF-8/UTF-16/BOM/latin1 for external JSON files.
  String _decodeTextWithFallback(List<int> bytes) {
    if (bytes.isEmpty) {
      return '';
    }

    if (_hasPrefix(bytes, const [0xEF, 0xBB, 0xBF])) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }

    if (_hasPrefix(bytes, const [0xFF, 0xFE])) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: true);
    }

    if (_hasPrefix(bytes, const [0xFE, 0xFF])) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: false);
    }

    try {
      return utf8.decode(bytes);
    } catch (_) {
      if (_looksLikeUtf16(bytes, littleEndian: true)) {
        return _decodeUtf16(bytes, littleEndian: true);
      }
      if (_looksLikeUtf16(bytes, littleEndian: false)) {
        return _decodeUtf16(bytes, littleEndian: false);
      }
      return latin1.decode(bytes);
    }
  }

  bool _hasPrefix(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeUtf16(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length < 4) {
      return false;
    }

    var zeroCount = 0;
    var checked = 0;
    final maxProbe = bytes.length > 200 ? 200 : bytes.length;
    for (var i = 0; i + 1 < maxProbe; i += 2) {
      checked++;
      final expectedZeroIndex = littleEndian ? i + 1 : i;
      if (bytes[expectedZeroIndex] == 0) {
        zeroCount++;
      }
    }

    if (checked == 0) {
      return false;
    }
    return zeroCount / checked > 0.35;
  }

  String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    final usableLength = bytes.length - (bytes.length % 2);
    final codeUnits = <int>[];
    for (var i = 0; i < usableLength; i += 2) {
      final unit = littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1];
      codeUnits.add(unit);
    }
    return String.fromCharCodes(codeUnits);
  }

  // Centralized import runner with consistent busy state and snackbar output.
  Future<void> _runImport(
    String jsonText, {
    required ImportMode importMode,
  }) async {
    setState(() {
      _isBusy = true;
    });

    try {
      final result = await _dbHelper.importFromJson(jsonText, mode: importMode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported: ${result.timelines} timelines, ${result.fields} fields, ${result.entries} entries, ${result.values} values | Skipped: ${result.skippedEntries} | Updated: ${result.updatedEntries}',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid JSON: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import JSON: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _formatDateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
