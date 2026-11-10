import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';
import '../models/field.dart';
import '../models/timeline.dart';
import '../models/value.dart';
import 'firebase_helper.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:geocoding/geocoding.dart';

import '../data/export_value.dart';
import '../data/timeline_name.dart';

class DBHelper {
  DBHelper._internal();

  static final DBHelper instance = DBHelper._internal();

  static const defaultTimelineTemplates = <Map<String, dynamic>>[
    {
      'name': 'Favorite Restaurants',
      'fields': [
        {'name': 'Name', 'type': 'text'},
        {'name': 'Address', 'type': 'text'},
        {'name': 'Rating', 'type': 'number'},
        {'name': 'Best Meal', 'type': 'text'},
      ],
      'entries': <Map<String, dynamic>>[],
    },
    {
      'name': 'Books',
      'fields': [
        {'name': 'Book', 'type': 'text'},
        {'name': 'Rating', 'type': 'text'},
        {'name': 'Read_Status', 'type': 'text'},
        {'name': 'Review', 'type': 'text'},
        {'name': 'Includes_Spoilers', 'type': 'text'},
        {'name': 'Notes', 'type': 'text'},
        {'name': 'Updated_At', 'type': 'text'},
      ],
      'entries': <Map<String, dynamic>>[],
    },
    {
      'name': 'Songs',
      'fields': [
        {'name': 'Track', 'type': 'text'},
        {'name': 'Artist', 'type': 'text'},
        {'name': 'End_Time', 'type': 'text'},
        {'name': 'Ms_Played', 'type': 'number'},
      ],
      'entries': <Map<String, dynamic>>[],
    },
    {
      'name': 'Places',
      'fields': [
        {'name': 'Date', 'type': 'text'},
        {'name': 'Country', 'type': 'text'},
        {'name': 'City', 'type': 'text'},
        {'name': 'Latitude', 'type': 'text'},
        {'name': 'Longitude', 'type': 'text'},
      ],
      'entries': <Map<String, dynamic>>[],
    },
  ];

  Database? _database;

  Future<Database> get database async {
    _database ??= await initDB();
    return _database!;
  }

  // Creates/opens the local SQLite database and applies migrations.
 Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digital_lifelines.db');

    // Delete old database to force fresh start!
    //await deleteDatabase(path);

    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
    await db.execute('''
          CREATE TABLE timelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            firebase_doc_id TEXT
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

        await _seedDefaultTimelines(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE entries ADD COLUMN is_favorite INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE timelines ADD COLUMN firebase_doc_id TEXT',
          );
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE timelines ADD COLUMN firebase_doc_id TEXT',
            );
          } catch (e) {
            print('Column may already exist: $e');
          }
        }
        if (oldVersion < 6) {
          await _migrateLegacyTimelineNames(db);
          await _seedDefaultTimelines(db);
        }
      },
    );
  }

  Future<void> _seedDefaultTimelines(DatabaseExecutor db) async {
    final existingTimelines = await db.query(
      'timelines',
      columns: ['name'],
    );
    final existingNames = existingTimelines
        .map((row) => _normalizeKey((row['name'] ?? '').toString()))
        .toSet();

    for (final template in defaultTimelineTemplates.reversed) {
      final name = template['name'] as String;
      if (!existingNames.add(_normalizeKey(name))) continue;

      final timelineId = await db.insert('timelines', {'name': name});
      for (final field in template['fields'] as List<Map<String, dynamic>>) {
        await db.insert('fields', {
          'timeline_id': timelineId,
          'name': field['name'],
          'type': field['type'],
        });
      }
    }
  }

  Future<void> _migrateLegacyTimelineNames(DatabaseExecutor db) async {
    const legacyNames = {
      'spotify streaming history': 'Songs',
      'goodreads reviews': 'Books',
      'my places': 'Places',
    };

    for (final entry in legacyNames.entries) {
      final timelines = await db.query('timelines');
      final matching = timelines.where((timeline) {
        return _normalizeKey((timeline['name'] ?? '').toString()) == entry.key;
      }).toList();
      if (matching.isEmpty) continue;

      final canonicalName = entry.value;
      Map<String, Object?>? canonical;
      for (final timeline in timelines) {
        if (_normalizeKey((timeline['name'] ?? '').toString()) ==
            _normalizeKey(canonicalName)) {
          canonical = timeline;
          break;
        }
      }

      int canonicalId;
      if (canonical == null) {
        canonicalId = matching.removeAt(0)['id'] as int;
        await db.update(
          'timelines',
          {'name': canonicalName},
          where: 'id = ?',
          whereArgs: [canonicalId],
        );
      } else {
        canonicalId = canonical['id'] as int;
      }

      for (final legacyTimeline in matching) {
        final legacyId = legacyTimeline['id'] as int;
        if (canonical != null &&
            canonical['firebase_doc_id'] == null &&
            legacyTimeline['firebase_doc_id'] != null) {
          await db.update(
            'timelines',
            {'firebase_doc_id': legacyTimeline['firebase_doc_id']},
            where: 'id = ?',
            whereArgs: [canonicalId],
          );
        }
        final canonicalFields = await db.query(
          'fields',
          where: 'timeline_id = ?',
          whereArgs: [canonicalId],
        );
        final fieldIdsByName = <String, int>{
          for (final field in canonicalFields)
            _normalizeKey((field['name'] ?? '').toString()): field['id'] as int,
        };
        final legacyFields = await db.query(
          'fields',
          where: 'timeline_id = ?',
          whereArgs: [legacyId],
        );

        for (final field in legacyFields) {
          final oldFieldId = field['id'] as int;
          final fieldName = (field['name'] ?? '').toString();
          final fieldKey = _normalizeKey(fieldName);
          final newFieldId =
              fieldIdsByName[fieldKey] ??
              await db.insert('fields', {
                'timeline_id': canonicalId,
                'name': fieldName,
                'type': field['type'],
              });
          fieldIdsByName[fieldKey] = newFieldId;
          await db.rawUpdate(
            'UPDATE "values" SET field_id = ? WHERE field_id = ?',
            [newFieldId, oldFieldId],
          );
        }

        await db.update(
          'entries',
          {'timeline_id': canonicalId},
          where: 'timeline_id = ?',
          whereArgs: [legacyId],
        );
        await db.delete(
          'fields',
          where: 'timeline_id = ?',
          whereArgs: [legacyId],
        );
        await db.delete(
          'timelines',
          where: 'id = ?',
          whereArgs: [legacyId],
        );
      }
    }
  }

/*Future<int> insertTimeline(Timeline timeline) async {
    final db = await database;
    final localId = await db.insert('timelines', timeline.toMap());
    
    // Save to Firebase and get doc ID!
    final firebaseDocId = await FirebaseHelper.instance
        .saveTimeline(timeline.name, localId);
    
    // Store firebase doc ID locally!
    await db.update(
      'timelines',
      {'firebase_doc_id': firebaseDocId},
      where: 'id = ?',
      whereArgs: [localId],
    );
    
    return localId;
  }
  */
  Future<int> insertTimeline(Timeline timeline) async {
  final db = await database;
  return await db.insert('timelines', timeline.toMap());
}

 Future<String> getFirebaseDocId(int timelineId) async {
    final db = await database;
    final rows = await db.query(
      'timelines',
      where: 'id = ?',
      whereArgs: [timelineId],
    );
    if (rows.isEmpty) return timelineId.toString();
    return (rows.first['firebase_doc_id'] as String?) ?? timelineId.toString();
  }

Future<int> updateTimelineName({
    required int timelineId,
    required String name,
  }) async {
    final db = await database;
    
    // Get Firebase doc ID first!
    final firebaseDocId = await getFirebaseDocId(timelineId);
    
    // Update Firebase!
    await FirebaseHelper.instance
        .updateTimelineName(firebaseDocId, name);
    
    return db.update(
      'timelines',
      {'name': name},
      where: 'id = ?',
      whereArgs: [timelineId],
    );
  }
/*
 Future<int> insertField(TimelineField field) async {
    final db = await database;
    final fieldId = await db.insert('fields', field.toMap());
    
    // Get Firebase doc ID!
    final firebaseDocId = await getFirebaseDocId(field.timelineId);
    
    await FirebaseHelper.instance.saveField(
      firebaseDocId,
      field.name,
      field.type,
    );
    
    return fieldId;
  }
  */

  Future<int> insertField(TimelineField field) async {
  final db = await database;
  return await db.insert('fields', field.toMap());
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
/*
Future<int> insertEntry(Entry entry) async {
    final db = await database;
    final entryId = await db.insert('entries', entry.toMap());
    
    // Get Firebase doc ID!
    final firebaseDocId = await getFirebaseDocId(entry.timelineId);
    
   await FirebaseHelper.instance.saveEntry(
      firebaseDocId,
      entryId,
      {}, // Empty! Values saved separately via insertValue!
    );
    
    return entryId;
  }
  */

  Future<int> insertEntry(Entry entry) async {
  final db = await database;
  return await db.insert('entries', entry.toMap());
}

/*
 Future<int> insertValue(EntryValue value) async {
    final db = await database;
    final id = await db.rawInsert(
      'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
      [value.entryId, value.fieldId, value.value],
    );
    
    // Get field name for Firebase
    final fieldRows = await db.query(
      'fields',
      where: 'id = ?',
      whereArgs: [value.fieldId],
    );
    
    if (fieldRows.isNotEmpty) {
      final fieldName = fieldRows.first['name'] as String;
      final timelineId = fieldRows.first['timeline_id'] as int;
      
   // Get Firebase doc ID!
      final firebaseDocId = await getFirebaseDocId(timelineId);
      
      // Save to Firebase!
      await FirebaseHelper.instance.saveValue(
        firebaseDocId,
        value.entryId,
        fieldName,
        value.value,
      );
    }
    
    return id;
  }
  */

  Future<int> insertValue(EntryValue value) async {
  final db = await database;
  return await db.rawInsert(
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

  // Clear all local data on logout
Future<void> clearAllData() async {
    final db = await database;
    await db.rawDelete('DELETE FROM "values"');
    await db.rawDelete('DELETE FROM entries');
    await db.rawDelete('DELETE FROM fields');
    await db.rawDelete('DELETE FROM timelines');
    print('Local data cleared!');
  }

// Sync data from Firebase to local SQLite
Future<void> syncFromFirebase() async {
    try {
      final timelines = await FirebaseHelper.instance.getUserTimelines();
      
      final db = await database;
      
      for (final timeline in timelines) {
        final name = timeline['name'] as String? ?? '';
        if (name.isEmpty) continue;
        
       // Insert timeline with firebase_doc_id!
        final firebaseDocId = timeline['firebase_doc_id'] as String? ?? '';
        final timelineId = await db.insert(
          'timelines',
          {
            'name': name,
            'firebase_doc_id': firebaseDocId,
          },
        );
        
        // Insert fields
        final fields = timeline['fields'] as List? ?? [];
        for (final field in fields) {
          await db.insert('fields', {
            'timeline_id': timelineId,
            'name': field['name'] ?? '',
            'type': field['type'] ?? 'text',
          });
        }
        
      // Insert entries with values
        final entries = timeline['entries'] as List? ?? [];
        for (final entry in entries) {
          final entryId = await db.insert('entries', {
            'timeline_id': timelineId,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'is_favorite': 0,
          });

          // Insert values for this entry
          final values = entry['values'] as Map? ?? {};
          for (final pair in values.entries) {
            final fieldName = pair.key.toString();
            final fieldValue = pair.value.toString();

            // Find field_id by name
            final fieldRows = await db.query(
              'fields',
              where: 'timeline_id = ? AND name = ?',
              whereArgs: [timelineId, fieldName],
            );

            if (fieldRows.isNotEmpty) {
              final fieldId = fieldRows.first['id'] as int;
              await db.rawInsert(
                'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
                [entryId, fieldId, fieldValue],
              );
            }
          }
        }
      }
      print('Synced from Firebase successfully!');
    } catch (e) {
      print('Sync error: $e');
    }
  }

// Call this only when user explicitly wants to backup
Future<void> backupToFirebase() async {
  final timelines = await getTimelines();
  
  for (final timeline in timelines) {
    final timelineId = timeline.id;
    if (timelineId == null) continue;
    
    final firebaseDocId = await FirebaseHelper.instance
        .saveTimeline(timeline.name, timelineId);
    
    final fields = await getFields(timelineId);
    for (final field in fields) {
      await FirebaseHelper.instance
          .saveField(firebaseDocId, field.name, field.type);
    }
    
    final entries = await getEntries(timelineId);
    for (final entry in entries) {
      final entryId = entry.id;
      if (entryId == null) continue;
      
    /*  await FirebaseHelper.instance
          .saveEntry(firebaseDocId, entryId, entry.createdAt, entry.isFavorite);
    */
        await FirebaseHelper.instance.saveEntry(
      firebaseDocId,
      entryId,
      {
        'created_at': entry.createdAt.toString(),
        'is_favorite': entry.isFavorite.toString(),
      },
    );  
      final values = await getValues(entryId);
      for (final value in values) {
        final fieldRows = await (await database).query(
          'fields', where: 'id = ?', whereArgs: [value.fieldId]);
        if (fieldRows.isNotEmpty) {
          final fieldName = fieldRows.first['name'] as String;
        /*  await FirebaseHelper.instance
              .saveValue(timelineId, entryId, fieldName, value.value);
        */
        await FirebaseHelper.instance
    .saveValue(timelineId.toString(), entryId, fieldName, value.value);
        }
      }
    }
  }
}



Future<void> deleteTimeline(int timelineId) async {
    final db = await database;
    
    // Get Firebase doc ID BEFORE deleting locally!
    final firebaseDocId = await getFirebaseDocId(timelineId);
    
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

   // Also delete from Firebase!
    await FirebaseHelper.instance.deleteTimeline(firebaseDocId);
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

  // Empty importable templates also serve as the first-run lifeline defaults.
  Map<String, dynamic> buildTemplateJson() {
    return {
      'schema_version': 1,
      'app': 'Digital Lifelines',
      'type': 'template',
      'timelines': defaultTimelineTemplates,
    };
  }

  // Exports full app data to a portable JSON structure.
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
        final valuesByFieldName = <String, dynamic>{};

        for (final value in values) {
          final fieldName = fieldNamesById[value.fieldId];
          if (fieldName == null) continue;
          valuesByFieldName[fieldName] = exportValueForField(
            fieldName,
            value.value,
          );
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

  // Imports timeline data with support for replace, merge-skip, and merge-update modes.
  Future<ImportResult> importFromJson(
    String jsonText, {
    ImportMode mode = ImportMode.mergeSkipDuplicates,
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
    var skippedEntries = 0;
    var updatedEntries = 0;

    // One transaction keeps import atomic and faster.
    await db.transaction((txn) async {
      if (mode == ImportMode.replaceAll) {
        await txn.rawDelete('DELETE FROM "values"');
        await txn.rawDelete('DELETE FROM entries');
        await txn.rawDelete('DELETE FROM fields');
        await txn.rawDelete('DELETE FROM timelines');
      }

      final timelineIdsByName = <String, int>{};
      if (mode != ImportMode.replaceAll) {
        final existingTimelines = await txn.query('timelines');
        for (final row in existingTimelines) {
          final id = row['id'] as int?;
          final name = (row['name'] ?? '').toString();
          if (id == null) continue;
          final normalized = _normalizeKey(name);
          if (normalized.isEmpty) continue;
          timelineIdsByName[normalized] = id;
          timelineIdsByName[_normalizeKey(canonicalTimelineName(name))] ??= id;
        }
      }

      for (final timelineRaw in timelinesRaw) {
        if (timelineRaw is! Map) continue;

        final sourceTimelineName = (timelineRaw['name'] ?? '').toString().trim();
        if (sourceTimelineName.isEmpty) continue;
        final timelineName = canonicalTimelineName(sourceTimelineName);

        final timelineNameKey = _normalizeKey(timelineName);
        int timelineId;
        final matchedTimelineId = timelineIdsByName[timelineNameKey];
        if (matchedTimelineId != null) {
          timelineId = matchedTimelineId;
        } else {
          timelineId = await txn.insert('timelines', {'name': timelineName});
          importedTimelines++;
          timelineIdsByName[timelineNameKey] = timelineId;
        }

        final fieldsRaw = timelineRaw['fields'];
        if (fieldsRaw is! List) continue;

        final fieldIdsByName = <String, int>{};
        final existingFields = await txn.query(
          'fields',
          where: 'timeline_id = ?',
          whereArgs: [timelineId],
        );
        for (final existingField in existingFields) {
          final fieldId = existingField['id'] as int?;
          final fieldName = (existingField['name'] ?? '').toString().trim();
          if (fieldId == null || fieldName.isEmpty) continue;
          fieldIdsByName[_normalizeKey(fieldName)] = fieldId;
        }

        for (final fieldRaw in fieldsRaw) {
          if (fieldRaw is! Map) continue;

          final fieldName = (fieldRaw['name'] ?? '').toString().trim();
          if (fieldName.isEmpty) continue;
          final fieldNameKey = _normalizeKey(fieldName);

          final rawType = (fieldRaw['type'] ?? 'text').toString().trim();
          final fieldType = rawType == 'number' ? 'number' : 'text';

          final existingFieldId = fieldIdsByName[fieldNameKey];
          if (existingFieldId != null) {
            if (mode == ImportMode.mergeUpdateDuplicates) {
              await txn.update(
                'fields',
                {'type': fieldType},
                where: 'id = ?',
                whereArgs: [existingFieldId],
              );
            }
          } else {
            final fieldId = await txn.insert('fields', {
              'timeline_id': timelineId,
              'name': fieldName,
              'type': fieldType,
            });
            importedFields++;
            fieldIdsByName[fieldNameKey] = fieldId;
          }
        }

        // Build duplicate lookup once per timeline for consistent merge behavior.
        final duplicateIndex = await _buildEntryDuplicateIndex(
          txn: txn,
          timelineId: timelineId,
          fieldIdsByName: fieldIdsByName,
        );

        final entriesRaw = timelineRaw['entries'];
        if (entriesRaw is! List) continue;

        for (final entryRaw in entriesRaw) {
          if (entryRaw is! Map) continue;

          final createdAtRaw = entryRaw['created_at'];
          final createdAt = createdAtRaw is int
              ? createdAtRaw
              : DateTime.now().millisecondsSinceEpoch;

          final valuesRaw = entryRaw['values'];
          if (valuesRaw is! Map) continue;

          final valuesByFieldName = <String, String>{};
          final valuesByFieldId = <int, String>{};
          for (final pair in valuesRaw.entries) {
            final fieldName = pair.key.toString();
            final normalizedFieldName = _normalizeKey(fieldName);
            if (normalizedFieldName.isEmpty) continue;

            final fieldId = fieldIdsByName[normalizedFieldName];
            if (fieldId == null) continue;

            final valueText = (pair.value ?? '').toString();
            valuesByFieldName[normalizedFieldName] = valueText;
            valuesByFieldId[fieldId] = valueText;
          }

          final entryNameKey = _extractEntryNameKey(valuesByFieldName);
          final signature = _buildEntrySignature(valuesByFieldName);

          int? existingEntryId;
          if (entryNameKey != null) {
            existingEntryId = duplicateIndex.entryIdByName[entryNameKey];
          }
          if (existingEntryId == null && signature.isNotEmpty) {
            existingEntryId = duplicateIndex.entryIdBySignature[signature];
          }

          if (mode == ImportMode.mergeSkipDuplicates &&
              existingEntryId != null) {
            skippedEntries++;
            continue;
          }

          final isFavorite =
              (entryRaw['is_favorite'] == true || entryRaw['is_favorite'] == 1)
              ? 1
              : 0;

          int entryId;
          if (mode == ImportMode.mergeUpdateDuplicates &&
              existingEntryId != null) {
            entryId = existingEntryId;
            await txn.update(
              'entries',
              {'created_at': createdAt, 'is_favorite': isFavorite},
              where: 'id = ?',
              whereArgs: [entryId],
            );
            updatedEntries++;
          } else {
            entryId = await txn.insert('entries', {
              'timeline_id': timelineId,
              'created_at': createdAt,
              'is_favorite': isFavorite,
            });
            importedEntries++;
          }

          for (final pair in valuesByFieldId.entries) {
            final fieldId = pair.key;
            final valueText = pair.value;

            if (mode == ImportMode.mergeUpdateDuplicates &&
                existingEntryId != null) {
              final existingValue = await txn.rawQuery(
                'SELECT id FROM "values" WHERE entry_id = ? AND field_id = ? LIMIT 1',
                [entryId, fieldId],
              );
              if (existingValue.isEmpty) {
                await txn.rawInsert(
                  'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
                  [entryId, fieldId, valueText],
                );
                importedValues++;
              } else {
                final valueId = existingValue.first['id'] as int;
                await txn.rawUpdate(
                  'UPDATE "values" SET value = ? WHERE id = ?',
                  [valueText, valueId],
                );
              }
            } else {
              await txn.rawInsert(
                'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
                [entryId, fieldId, valueText],
              );
              importedValues++;
            }
          }

          if (entryNameKey != null) {
            duplicateIndex.entryIdByName[entryNameKey] = entryId;
          }
          if (signature.isNotEmpty) {
            duplicateIndex.entryIdBySignature[signature] = entryId;
          }
        }
      }
    });

    return ImportResult(
      timelines: importedTimelines,
      fields: importedFields,
      entries: importedEntries,
      values: importedValues,
      skippedEntries: skippedEntries,
      updatedEntries: updatedEntries,
    );
  }

  // Normalizes user-provided keys to make matching case-insensitive.
  String _normalizeKey(String value) {
    return value.trim().toLowerCase();
  }

  // Uses title/name as a primary duplicate key when available.
  String? _extractEntryNameKey(Map<String, String> valuesByFieldName) {
    final title = valuesByFieldName['title'];
    final name = valuesByFieldName['name'];

    final primary = (title ?? name ?? '').trim();
    if (primary.isEmpty) return null;
    return _normalizeKey(primary);
  }

  // Fallback duplicate signature across all fields.
  String _buildEntrySignature(Map<String, String> valuesByFieldName) {
    final pairs = valuesByFieldName.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return pairs
        .map((pair) => '${pair.key}:${_normalizeKey(pair.value)}')
        .join('|');
  }

  Future<void> backupSelectedToFirebase(List<Timeline> timelines) async {
  for (final timeline in timelines) {
    final timelineId = timeline.id;
    if (timelineId == null) continue;

    final firebaseDocId = await FirebaseHelper.instance
        .saveTimeline(timeline.name, timelineId);

    final fields = await getFields(timelineId);
    for (final field in fields) {
      await FirebaseHelper.instance
          .saveField(firebaseDocId, field.name, field.type);
    }

    final entries = await getEntries(timelineId);
    for (final entry in entries) {
      final entryId = entry.id;
      if (entryId == null) continue;

      await FirebaseHelper.instance.saveEntry(
        firebaseDocId,
        entryId,
        {
          'created_at': entry.createdAt.toString(),
          'is_favorite': entry.isFavorite.toString(),
        },
      );

      final values = await getValues(entryId);
      for (final value in values) {
        final fieldRows = await (await database).query(
          'fields', where: 'id = ?', whereArgs: [value.fieldId]);
        if (fieldRows.isNotEmpty) {
          final fieldName = fieldRows.first['name'] as String;
          await FirebaseHelper.instance
              .saveValue(timelineId.toString(), entryId, fieldName, value.value);
        }
      }
    }
  }
}

  // Reads existing entries and builds indexes for duplicate detection.
  Future<_EntryDuplicateIndex> _buildEntryDuplicateIndex({
    required Transaction txn,
    required int timelineId,
    required Map<String, int> fieldIdsByName,
  }) async {
    final rows = await txn.rawQuery(
      'SELECT e.id AS entry_id, f.id AS field_id, v.value AS value_text '
      'FROM entries e '
      'LEFT JOIN "values" v ON v.entry_id = e.id '
      'LEFT JOIN fields f ON f.id = v.field_id '
      'WHERE e.timeline_id = ? '
      'ORDER BY e.id ASC',
      [timelineId],
    );

    final fieldNameById = <int, String>{
      for (final pair in fieldIdsByName.entries) pair.value: pair.key,
    };
    final valuesByEntryId = <int, Map<String, String>>{};

    for (final row in rows) {
      final entryId = row['entry_id'] as int?;
      if (entryId == null) continue;

      final fieldId = row['field_id'] as int?;
      if (fieldId == null) continue;

      final fieldName = fieldNameById[fieldId];
      if (fieldName == null) continue;

      final valueText = (row['value_text'] ?? '').toString();
      valuesByEntryId.putIfAbsent(entryId, () => {})[fieldName] = valueText;
    }

    final byName = <String, int>{};
    final bySignature = <String, int>{};

    for (final pair in valuesByEntryId.entries) {
      final entryId = pair.key;
      final values = pair.value;

      final nameKey = _extractEntryNameKey(values);
      if (nameKey != null) {
        byName[nameKey] = entryId;
      }

      final signature = _buildEntrySignature(values);
      if (signature.isNotEmpty) {
        bySignature[signature] = entryId;
      }
    }

    return _EntryDuplicateIndex(
      entryIdByName: byName,
      entryIdBySignature: bySignature,
    );
  }


/// Photo library permission options shared by the photo import and backfill.
/// `mediaLocation` lets Android read the GPS data stored in each photo.
static const PermissionRequestOption photoPermissionOption =
    PermissionRequestOption(
  androidPermission: AndroidPermission(
    type: RequestType.image,
    mediaLocation: true,
  ),
);

/// Scans the photos the app can see and adds their locations to the
/// "Places" timeline. Only the GPS coordinates and the date of each photo
/// are read; the photos themselves are never copied or stored.
///
/// Safe to run again: photos that were already imported are skipped, so new
/// photos (or newly shared ones under limited access) get added.
///
/// Location services are NOT needed here. The coordinates come from the
/// photo's own metadata, and turning coordinates into a city name uses the
/// system geocoder, which works without location permission.
Future<PhotoImportResult> importFromPhotos() async {
  final permission = await PhotoManager.requestPermissionExtend(
    requestOption: photoPermissionOption,
  );
  if (!permission.hasAccess) {
    print('Photo permission denied!');
    return const PhotoImportResult(permissionGranted: false);
  }

  // The "all photos" album holds every photo the app can see (only the
  // selected ones under limited access), so no need to walk every album.
  final albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );
  final List<AssetEntity> photos = [];
  if (albums.isNotEmpty) {
    final album = albums.first;
    final total = await album.assetCountAsync;
    const pageSize = 500;
    for (var start = 0; start < total; start += pageSize) {
      photos.addAll(
        await album.getAssetListRange(start: start, end: start + pageSize),
      );
    }
  }
  print('Photos found: ${photos.length}');

  final db = await database;

  // Reuse "Places" (or the legacy name) and remember which photos are already in
  // it (matched by the photo's exact creation time).
  int? timelineId;
  final Map<String, int> fieldIds = {};
  final Set<int> importedTimestamps = {};
  var existing = await db.query(
    'timelines',
    where: 'LOWER(TRIM(name)) = ?',
    whereArgs: ['places'],
    limit: 1,
  );
  if (existing.isEmpty) {
    existing = await db.query(
      'timelines',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: ['my places'],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'timelines',
        {'name': 'Places'},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }
  if (existing.isNotEmpty) {
    timelineId = existing.first['id'] as int;
    final fields = await db.query(
      'fields',
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
    );
    for (final f in fields) {
      fieldIds[_normalizeKey(f['name'] as String)] = f['id'] as int;
    }
    final entries = await db.query(
      'entries',
      columns: ['created_at'],
      where: 'timeline_id = ?',
      whereArgs: [timelineId],
    );
    for (final e in entries) {
      final createdAt = e['created_at'];
      if (createdAt is int) importedTimestamps.add(createdAt);
    }
  }

  // Creates the timeline and any missing fields the first time a new place
  // is found, so an import with no results doesn't leave an empty timeline.
  Future<int> ensureTimeline() async {
    timelineId ??= await db.insert('timelines', {'name': 'Places'});
    const fields = {
      'date': 'Date',
      'country': 'Country',
      'city': 'City',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
    };
    for (final field in fields.entries) {
      fieldIds[field.key] ??= await db.insert('fields', {
        'timeline_id': timelineId,
        'name': field.value,
        'type': 'text',
      });
    }
    return timelineId!;
  }

  final Map<String, Map<String, String>> geocodeCache = {};
  int withLocation = 0;
  int added = 0;
  int alreadyImported = 0;
  // Photos taken in the same second as another photo in this scan (usually a
  // burst). Creation times only have one-second precision, so these would be
  // identical entries; only the first one is kept.
  int sameMoment = 0;
  final Set<int> timestampsThisScan = {};

  for (final photo in photos) {
    try {
      final latLng = await photo.latlngAsync();
      // Some Android versions report 0,0 instead of "no location".
      if (latLng == null ||
          (latLng.latitude == 0 && latLng.longitude == 0)) {
        continue;
      }
      withLocation++;

      final createdAt = photo.createDateTime.millisecondsSinceEpoch;
      if (timestampsThisScan.contains(createdAt)) {
        sameMoment++;
        continue;
      }
      if (importedTimestamps.contains(createdAt)) {
        timestampsThisScan.add(createdAt);
        alreadyImported++;
        continue;
      }

      final lat = latLng.latitude;
      final lng = latLng.longitude;

      String country = 'Unknown';
      String city = 'Unknown';
      // Round coordinates to ~1km precision to group nearby photos together
      final cacheKey = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';

      if (geocodeCache.containsKey(cacheKey)) {
        country = geocodeCache[cacheKey]!['country']!;
        city = geocodeCache[cacheKey]!['city']!;
      } else {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            country = place.country ?? 'Unknown';
            city = place.locality ?? place.administrativeArea ?? 'Unknown';
          }
          geocodeCache[cacheKey] = {'country': country, 'city': city};
          // Small delay only for actual network calls
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('Geocoding failed for $lat, $lng: $e');
          geocodeCache[cacheKey] = {'country': country, 'city': city};
        }
      }
      final date = photo.createDateTime.toIso8601String().split('T').first;

      final tId = await ensureTimeline();
      final entryId = await db.insert('entries', {
        'timeline_id': tId,
        'created_at': createdAt,
        'is_favorite': 0,
      });

      final values = {
        'date': date,
        'country': country,
        'city': city,
        'latitude': lat.toString(),
        'longitude': lng.toString(),
      };
      for (final v in values.entries) {
        await db.rawInsert(
          'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
          [entryId, fieldIds[v.key], v.value],
        );
      }
      importedTimestamps.add(createdAt);
      timestampsThisScan.add(createdAt);
      added++;
    } catch (e) {
      print('Error processing photo: $e');
      continue;
    }
  }

  print('Scanned ${photos.length} photos, $withLocation with location, '
      'added $added new places, $alreadyImported already imported, '
      '$sameMoment taken at the same time as another photo.');
  return PhotoImportResult(
    permissionGranted: true,
    limitedAccess: permission == PermissionState.limited,
    photosScanned: photos.length,
    photosWithLocation: withLocation,
    placesAdded: added,
    alreadyImported: alreadyImported,
    sameMomentSkipped: sameMoment,
  );
}

/// Adds latitude/longitude to existing "Places" entries that were
/// imported before coordinates were being saved. Matches each existing
/// entry back to its original photo using the exact creation timestamp,
/// which is stored for both.
Future<int> backfillPhotoCoordinates() async {
  final db = await database;

  var existing = await db.query(
    'timelines',
    where: 'LOWER(TRIM(name)) = ?',
    whereArgs: ['places'],
  );
  if (existing.isEmpty) {
    existing = await db.query(
      'timelines',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: ['my places'],
    );
  }
  if (existing.isEmpty) {
    print('Places does not exist yet - nothing to backfill.');
    return 0;
  }
  final timelineId = existing.first['id'] as int;

  final existingFields = await db.query(
    'fields',
    where: 'timeline_id = ?',
    whereArgs: [timelineId],
  );
  int? latFieldId;
  int? lngFieldId;
  for (final f in existingFields) {
    if (_normalizeKey(f['name'] as String) == 'latitude') {
      latFieldId = f['id'] as int;
    }
    if (_normalizeKey(f['name'] as String) == 'longitude') {
      lngFieldId = f['id'] as int;
    }
  }
  latFieldId ??= await db.insert('fields', {
    'timeline_id': timelineId, 'name': 'Latitude', 'type': 'text',
  });
  lngFieldId ??= await db.insert('fields', {
    'timeline_id': timelineId, 'name': 'Longitude', 'type': 'text',
  });

  final existingEntries = await db.query(
    'entries',
    where: 'timeline_id = ?',
    whereArgs: [timelineId],
  );
  final entryIdByTimestamp = <int, int>{};
  for (final e in existingEntries) {
    entryIdByTimestamp[e['created_at'] as int] = e['id'] as int;
  }

  final existingCoordValues = await db.query(
    'values',
    where: 'field_id = ?',
    whereArgs: [latFieldId],
  );
  final entriesWithCoords =
      existingCoordValues.map((v) => v['entry_id'] as int).toSet();

  final permission = await PhotoManager.requestPermissionExtend(
    requestOption: photoPermissionOption,
  );
  if (!permission.hasAccess) {
    print('Photo permission denied during backfill!');
    return 0;
  }

  final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
  if (albums.isEmpty) return 0;
  final List<AssetEntity> photos = [];
  for (final album in albums) {
    final assets = await album.getAssetListRange(start: 0, end: 1000);
    for (final asset in assets) {
      if (!photos.any((p) => p.id == asset.id)) {
        photos.add(asset);
      }
    }
  }

  int backfilled = 0;
  for (final photo in photos) {
    try {
      final timestamp = photo.createDateTime.millisecondsSinceEpoch;
      final entryId = entryIdByTimestamp[timestamp];
      if (entryId == null) continue;
      if (entriesWithCoords.contains(entryId)) continue;

      final latLng = await photo.latlngAsync();
      if (latLng == null) continue;
      final lat = latLng.latitude;
      final lng = latLng.longitude;

      await db.rawInsert(
        'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
        [entryId, latFieldId, lat.toString()],
      );
      await db.rawInsert(
        'INSERT INTO "values" (entry_id, field_id, value) VALUES (?, ?, ?)',
        [entryId, lngFieldId, lng.toString()],
      );
      backfilled++;
    } catch (e) {
      print('Error backfilling photo coordinates: $e');
      continue;
    }
  }
  print('Backfilled coordinates for $backfilled entries!');
  return backfilled;
}
  
}

enum ImportMode { replaceAll, mergeSkipDuplicates, mergeUpdateDuplicates }

class ImportResult {
  final int timelines;
  final int fields;
  final int entries;
  final int values;
  final int skippedEntries;
  final int updatedEntries;

  const ImportResult({
    required this.timelines,
    required this.fields,
    required this.entries,
    required this.values,
    this.skippedEntries = 0,
    this.updatedEntries = 0,
  });

}


class _EntryDuplicateIndex {
  final Map<String, int> entryIdByName;
  final Map<String, int> entryIdBySignature;

  _EntryDuplicateIndex({
    required this.entryIdByName,
    required this.entryIdBySignature,
  });
}

/// Outcome of [DBHelper.importFromPhotos], used to tell the user what was found.
class PhotoImportResult {
  final bool permissionGranted;
  final bool limitedAccess;
  final int photosScanned;
  final int photosWithLocation;
  final int placesAdded;

  /// Photos skipped because they were already in "My Places".
  final int alreadyImported;

  /// Photos skipped because another photo was taken in the same second
  /// (usually a burst), so they would have been identical entries.
  final int sameMomentSkipped;

  const PhotoImportResult({
    required this.permissionGranted,
    this.limitedAccess = false,
    this.photosScanned = 0,
    this.photosWithLocation = 0,
    this.placesAdded = 0,
    this.alreadyImported = 0,
    this.sameMomentSkipped = 0,
  });
}
