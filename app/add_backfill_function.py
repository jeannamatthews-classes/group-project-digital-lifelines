path = 'lib/database/db_helper.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

anchor = """  print('Imported $count places from photos!');
  return count;
}"""

new_function = '''

/// Adds latitude/longitude to existing "My Places" entries that were
/// imported before coordinates were being saved. Matches each existing
/// entry back to its original photo using the exact creation timestamp,
/// which is stored for both.
Future<int> backfillPhotoCoordinates() async {
  final db = await database;

  final existing = await db.query(
    'timelines',
    where: 'name = ?',
    whereArgs: ['My Places'],
  );
  if (existing.isEmpty) {
    print('My Places does not exist yet - nothing to backfill.');
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
    if (f['name'] == 'latitude') latFieldId = f['id'] as int;
    if (f['name'] == 'longitude') lngFieldId = f['id'] as int;
  }
  latFieldId ??= await db.insert('fields', {
    'timeline_id': timelineId, 'name': 'latitude', 'type': 'text',
  });
  lngFieldId ??= await db.insert('fields', {
    'timeline_id': timelineId, 'name': 'longitude', 'type': 'text',
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
    requestOption: const PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.image,
        mediaLocation: true,
      ),
    ),
  );
  if (!permission.isAuth) {
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
      double lat = latLng?.latitude ?? 0.0;
      double lng = latLng?.longitude ?? 0.0;
      if (lat == 0.0 && lng == 0.0) continue;

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
}'''

if 'backfillPhotoCoordinates' in content:
    print("Backfill function already present")
elif anchor not in content:
    print("ERROR: anchor text not found - aborting")
else:
    content = content.replace(anchor, anchor + new_function, 1)
    print("Added backfillPhotoCoordinates function")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
