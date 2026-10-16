import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:digital_lifelines/data/timeline_export_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates one importable JSON file for each timeline', () {
    final bytes = buildTimelineExportArchive({
      'schema_version': 1,
      'app': 'Digital Lifelines',
      'type': 'export',
      'exported_at': '2026-10-16T00:00:00.000',
      'timelines': [
        {
          'name': 'Books',
          'fields': [
            {'name': 'title', 'type': 'text'},
          ],
          'entries': [
            {
              'created_at': 1000,
              'is_favorite': false,
              'values': {'title': 'Example'},
            },
          ],
        },
        {
          'name': '../Places',
          'fields': [
            {'name': 'city', 'type': 'text'},
          ],
          'entries': <Map<String, dynamic>>[],
        },
      ],
      'total_timelines': 2,
      'total_entries': 1,
    });

    final files = ZipDecoder().decodeBytes(bytes).files;
    expect(files.map((file) => file.name).toList(), [
      'timelines/001_Books.json',
      'timelines/002_Places.json',
    ]);

    final jsonExports = files
        .map(
          (file) =>
              jsonDecode(utf8.decode(file.content)) as Map<String, dynamic>,
        )
        .toList();
    expect(jsonExports, hasLength(2));
    expect(jsonExports[0]['total_timelines'], 1);
    expect(jsonExports[0]['total_entries'], 1);
    expect(jsonExports[0]['timelines'], hasLength(1));
    expect(jsonExports[0]['timelines'][0]['name'], 'Books');
    expect(jsonExports[1]['total_timelines'], 1);
    expect(jsonExports[1]['total_entries'], 0);
    expect(jsonExports[1]['timelines'], hasLength(1));
    expect(jsonExports[1]['timelines'][0]['name'], '../Places');
  });

  test('rejects an export without timelines', () {
    expect(
      () => buildTimelineExportArchive({'timelines': null}),
      throwsFormatException,
    );
  });
}
