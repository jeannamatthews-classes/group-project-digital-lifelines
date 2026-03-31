import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';

import '../../../database/db_helper.dart';
import '../../../theme/app_theme.dart';

class AboutActionsSection extends StatefulWidget {
  const AboutActionsSection({super.key});

  @override
  State<AboutActionsSection> createState() => _AboutActionsSectionState();
}

class _AboutActionsSectionState extends State<AboutActionsSection> {
  static const MethodChannel _filesChannel = MethodChannel(
    'digitallifelines/files',
  );

  final DBHelper _dbHelper = DBHelper.instance;
  bool _isBusy = false;
  String? _lastExportPath;

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

  Future<String> _saveExportFile(String jsonText, int timestamp) async {
    if (Platform.isAndroid) {
      try {
        final fileName = 'digital_lifelines_export_$timestamp.json';
        final saved = await _filesChannel.invokeMethod<String>(
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

  Future<void> _importJson() async {
    final controller = TextEditingController();
    var replaceExisting = false;

    final payload = await showDialog<_ImportDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Import JSON'),
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
                        decoration: const InputDecoration(
                          hintText: 'Paste your JSON here',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: replaceExisting,
                        onChanged: (value) {
                          setDialogState(() {
                            replaceExisting = value ?? false;
                          });
                        },
                        title: const Text('Replace existing data'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
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
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      _ImportDialogResult(
                        jsonText: controller.text,
                        replaceExisting: replaceExisting,
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

    await _runImport(
      payload.jsonText,
      replaceExisting: payload.replaceExisting,
    );
  }

  Future<void> _importJsonFromFile() async {
    var replaceExisting = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Import From File'),
              content: CheckboxListTile(
                value: replaceExisting,
                onChanged: (value) {
                  setDialogState(() {
                    replaceExisting = value ?? false;
                  });
                },
                title: const Text('Replace existing data'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
      picked = await FilePicker.platform.pickFiles(
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
    String? jsonText;
    if (selected.path != null && selected.path!.isNotEmpty) {
      jsonText = await File(selected.path!).readAsString();
    } else if (selected.bytes != null) {
      jsonText = utf8.decode(selected.bytes!);
    }

    if (jsonText == null || jsonText.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is empty or unreadable')),
      );
      return;
    }

    await _runImport(jsonText, replaceExisting: replaceExisting);
  }

  Future<void> _importJsonFromPath() async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Import From File Path'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText:
                  '/storage/emulated/0/Download/digital_lifelines_import.json',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Load'),
            ),
          ],
        );
      },
    );

    if (path == null || path.isEmpty) return;

    try {
      final jsonText = await File(path).readAsString();
      if (jsonText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File is empty')));
        return;
      }
      await _runImport(jsonText, replaceExisting: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read path: $e')));
    }
  }

  Future<void> _runImport(
    String jsonText, {
    required bool replaceExisting,
  }) async {
    setState(() {
      _isBusy = true;
    });

    try {
      final result = await _dbHelper.importFromJson(
        jsonText,
        replaceExisting: replaceExisting,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported: ${result.timelines} timelines, ${result.fields} fields, ${result.entries} entries, ${result.values} values',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Example Lifeline Categories',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniTag(label: 'Books', color: Color(0xFFFF7B7B)),
            _MiniTag(label: 'Movies', color: Color(0xFF6F79FF)),
            _MiniTag(label: 'Songs', color: Color(0xFFFFBF53)),
            _MiniTag(label: 'Places', color: Color(0xFF5CC48E)),
          ],
        ),
        const SizedBox(height: 14),
        _ActionButton(
          onPressed: _isBusy ? null : _showTemplateJson,
          icon: Icons.description_outlined,
          text: 'Show Template JSON',
        ),
        const SizedBox(height: 10),
        _ActionButton(
          onPressed: _isBusy ? null : _exportJsonToPhone,
          icon: Icons.upload_file_outlined,
          text: 'Export Data JSON to Phone',
        ),
        const SizedBox(height: 10),
        _ActionButton(
          onPressed: _isBusy ? null : _importJson,
          icon: Icons.download_for_offline_outlined,
          text: 'Import JSON (Paste)',
        ),
        const SizedBox(height: 10),
        _ActionButton(
          onPressed: _isBusy ? null : _importJsonFromFile,
          icon: Icons.folder_open_outlined,
          text: 'Import JSON From File',
        ),
        if (_lastExportPath != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last export: $_lastExportPath',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isBusy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String text;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ImportDialogResult {
  final String jsonText;
  final bool replaceExisting;

  const _ImportDialogResult({
    required this.jsonText,
    required this.replaceExisting,
  });
}
