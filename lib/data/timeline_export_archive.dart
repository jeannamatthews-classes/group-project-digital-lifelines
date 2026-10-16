import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

Uint8List buildTimelineExportArchive(Map<String, dynamic> export) {
  final timelines = export['timelines'];
  if (timelines is! List) {
    throw const FormatException('Export must contain a timelines list');
  }

  final archive = Archive();
  for (var index = 0; index < timelines.length; index++) {
    final timeline = timelines[index];
    if (timeline is! Map<String, dynamic>) {
      throw const FormatException('Timeline export must be an object');
    }

    final entries = timeline['entries'];
    if (entries is! List) {
      throw const FormatException(
        'Timeline export must contain an entries list',
      );
    }

    final timelineExport = <String, dynamic>{
      ...export,
      'timelines': [timeline],
      'total_timelines': 1,
      'total_entries': entries.length,
    };
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(timelineExport),
    );
    final timelineName = timeline['name'];
    final fileName = _safeFileName(
      timelineName is String ? timelineName : 'timeline',
    );
    final numberedFileName =
        '${(index + 1).toString().padLeft(3, '0')}_$fileName.json';

    archive.addFile(
      ArchiveFile('timelines/$numberedFileName', jsonBytes.length, jsonBytes),
    );
  }

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _safeFileName(String name) {
  final safeName = name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
  return safeName.isEmpty ? 'timeline' : safeName;
}
