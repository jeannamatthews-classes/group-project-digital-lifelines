import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';
import '../models/field.dart';
import '../models/timeline.dart';
import '../models/value.dart';

class DBHelper {
  DBHelper._internal();

  static final DBHelper instance = DBHelper._internal();
  Database? _database;

  Future<Database> get database async {
    _database ??= await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digital_lifelines.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE timelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE fields (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timeline_id INTEGER,
            name TEXT,
            type TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timeline_id INTEGER,
            created_at INTEGER,
            is_favorite INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE "values" (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id INTEGER,
            field_id INTEGER,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE entries ADD COLUMN is_favorite INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  Future<int> insertTimeline(Timeline timeline) async {
    final db = await database;
    return db.insert('timelines', timeline.toMap());
  }

  Future<int> updateTimelineName({
    required int timelineId,
    required String name,
  }) async {
    final db = await database;
    return db.update(
      'timelines',
      {'name': name},
      where: 'id = ?',
      whereArgs: [timelineId],
    );
  }

  Future<int> insertField(TimelineField field) async {
    final db = await database;
    return db.insert('fields', field.toMap());
  }

  Future<List<Timeline>> getTimelines() async {
    final db = await database;
    final maps = await db.query('timelines', orderBy: 'id DESC');
    return maps.map(Timeline.fromMap).toList();
  }

  Future<List<TimelineField>> getFields(int timelineId) async {
    final db = await database;
    final maps = await db.query(
      'fields',
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
      orderBy: 'id ASC',
    );
    return maps.map(TimelineField.fromMap).toList();
  }

  Future<int> insertEntry(Entry entry) async {
    final db = await database;
    return db.insert('entries', entry.toMap());
  }

  Future<int> insertValue(EntryValue value) async {
    final db = await database;
    return db.rawInsert(
      'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
      [value.entryId, value.fieldId, value.value],
    );
  }

  Future<List<Entry>> getEntries(int timelineId) async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
      orderBy: 'is_favorite DESC, id DESC',
    );
    return maps.map(Entry.fromMap).toList();
  }

  Future<void> setEntryFavorite({
    required int entryId,
    required bool isFavorite,
  }) async {
    final db = await database;
    await db.update(
      'entries',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<List<Entry>> getAllFavoriteEntries() async {
    final db = await database;
    final maps = await db.query(
      'entries',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map(Entry.fromMap).toList();
  }

  Future<List<EntryValue>> getValues(int entryId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT * FROM "values" WHERE entry_id = ? ORDER BY id ASC',
      [entryId],
    );
    return maps.map(EntryValue.fromMap).toList();
  }

  Future<Map<int, String>> getValueMap(int entryId) async {
    final values = await getValues(entryId);
    return {for (final value in values) value.fieldId: value.value};
  }

  Future<void> upsertValue({
    required int entryId,
    required int fieldId,
    required String value,
  }) async {
    final db = await database;
    final existing = await db.rawQuery(
      'SELECT id FROM "values" WHERE entry_id = ? AND field_id = ? LIMIT 1',
      [entryId, fieldId],
    );

    if (existing.isEmpty) {
      await db.rawInsert(
        'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
        [entryId, fieldId, value],
      );
      return;
    }

    final valueId = existing.first['id'] as int;
    await db.rawUpdate('UPDATE "values" SET value = ? WHERE id = ?', [
      value,
      valueId,
    ]);
  }

  Future<void> deleteEntry(int entryId) async {
    final db = await database;
    await db.rawDelete('DELETE FROM "values" WHERE entry_id = ?', [entryId]);
    await db.delete('entries', where: 'id = ?', whereArgs: [entryId]);
  }

  Future<void> deleteTimeline(int timelineId) async {
    final db = await database;
    final entries = await getEntries(timelineId);

    for (final entry in entries) {
      final entryId = entry.id;
      if (entryId != null) {
        await db.rawDelete('DELETE FROM "values" WHERE entry_id = ?', [
          entryId,
        ]);
      }
    }

    await db.delete(
      'entries',
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
    );
    await db.delete(
      'fields',
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
    );
    await db.delete('timelines', where: 'id = ?', whereArgs: [timelineId]);
  }

  Future<Map<String, int>> getTimelineStats(int timelineId) async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM entries WHERE timeline_id = ?',
            [timelineId],
          ),
        ) ??
        0;

    final favorites =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM entries WHERE timeline_id = ? AND is_favorite = 1',
            [timelineId],
          ),
        ) ??
        0;

    return {'total': total, 'favorites': favorites};
  }

  Map<String, dynamic> buildTemplateJson() {
    return {
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
              'created_at': 0,
              'is_favorite': true,
              'values': {
                'title': 'Example Book',
                'author': 'Author Name',
                'rating': '5',
              },
            },
          ],
        },
      ],
    };
  }

  Future<Map<String, dynamic>> exportToJson() async {
    final db = await database;
    final timelines = await getTimelines();

    final resultTimelines = <Map<String, dynamic>>[];

    for (final timeline in timelines) {
      final timelineId = timeline.id;
      if (timelineId == null) continue;

      final fields = await getFields(timelineId);
      final entries = await getEntries(timelineId);

      final fieldNamesById = <int, String>{};
      for (final field in fields) {
        final id = field.id;
        if (id == null) continue;
        fieldNamesById[id] = field.name;
      }

      final entryJson = <Map<String, dynamic>>[];
      for (final entry in entries) {
        final entryId = entry.id;
        if (entryId == null) continue;

        final values = await getValues(entryId);
        final valuesByFieldName = <String, String>{};

        for (final value in values) {
          final fieldName = fieldNamesById[value.fieldId];
          if (fieldName == null) continue;
          valuesByFieldName[fieldName] = value.value;
        }

        entryJson.add({
          'created_at': entry.createdAt,
          'is_favorite': entry.isFavorite,
          'values': valuesByFieldName,
        });
      }

      resultTimelines.add({
        'name': timeline.name,
        'fields': fields
            .map((field) => {'name': field.name, 'type': field.type})
            .toList(),
        'entries': entryJson,
      });
    }

    return {
      'schema_version': 1,
      'app': 'Digital Lifelines',
      'type': 'export',
      'exported_at': DateTime.now().toIso8601String(),
      'timelines': resultTimelines,
      'total_timelines': resultTimelines.length,
      'total_entries':
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM entries'),
          ) ??
          0,
    };
  }

  Future<ImportResult> importFromJson(
    String jsonText, {
    bool replaceExisting = false,
  }) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON root must be an object');
    }

    final timelinesRaw = decoded['timelines'];
    if (timelinesRaw is! List) {
      throw const FormatException('JSON must include a timelines array');
    }

    final db = await database;

    var importedTimelines = 0;
    var importedFields = 0;
    var importedEntries = 0;
    var importedValues = 0;

    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.rawDelete('DELETE FROM "values"');
        await txn.rawDelete('DELETE FROM entries');
        await txn.rawDelete('DELETE FROM fields');
        await txn.rawDelete('DELETE FROM timelines');
      }

      for (final timelineRaw in timelinesRaw) {
        if (timelineRaw is! Map) continue;

        final timelineName = (timelineRaw['name'] ?? '').toString().trim();
        if (timelineName.isEmpty) continue;

        final timelineId = await txn.insert('timelines', {
          'name': timelineName,
        });
        importedTimelines++;

        final fieldsRaw = timelineRaw['fields'];
        if (fieldsRaw is! List) continue;

        final fieldIdsByName = <String, int>{};
        for (final fieldRaw in fieldsRaw) {
          if (fieldRaw is! Map) continue;

          final fieldName = (fieldRaw['name'] ?? '').toString().trim();
          if (fieldName.isEmpty) continue;

          final rawType = (fieldRaw['type'] ?? 'text').toString().trim();
          final fieldType = rawType == 'number' ? 'number' : 'text';

          final fieldId = await txn.insert('fields', {
            'timeline_id': timelineId,
            'name': fieldName,
            'type': fieldType,
          });
          importedFields++;
          fieldIdsByName[fieldName] = fieldId;
        }

        final entriesRaw = timelineRaw['entries'];
        if (entriesRaw is! List) continue;

        for (final entryRaw in entriesRaw) {
          if (entryRaw is! Map) continue;

          final createdAtRaw = entryRaw['created_at'];
          final createdAt = createdAtRaw is int
              ? createdAtRaw
              : DateTime.now().millisecondsSinceEpoch;

          final entryId = await txn.insert('entries', {
            'timeline_id': timelineId,
            'created_at': createdAt,
            'is_favorite': (entryRaw['is_favorite'] == true ||
                    entryRaw['is_favorite'] == 1)
                ? 1
                : 0,
          });
          importedEntries++;

          final valuesRaw = entryRaw['values'];
          if (valuesRaw is! Map) continue;

          for (final pair in valuesRaw.entries) {
            final fieldName = pair.key.toString();
            final fieldId = fieldIdsByName[fieldName];
            if (fieldId == null) continue;

            final valueText = (pair.value ?? '').toString();
            await txn.rawInsert(
              'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
              [entryId, fieldId, valueText],
            );
            importedValues++;
          }
        }
      }
    });

    return ImportResult(
      timelines: importedTimelines,
      fields: importedFields,
      entries: importedEntries,
      values: importedValues,
    );
  }
}

class ImportResult {
  final int timelines;
  final int fields;
  final int entries;
  final int values;

  const ImportResult({
    required this.timelines,
    required this.fields,
    required this.entries,
    required this.values,
  });
}
